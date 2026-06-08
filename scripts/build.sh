#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <upstream-tag> <linux-amd64|linux-arm64|windows-amd64> [build-revision]" >&2
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage
  exit 2
fi

upstream_ref="$1"
target="$2"
build_revision="${3:-1}"
upstream_repo="https://github.com/SagerNet/sing-box.git"

case "$target" in
  linux-amd64)
    goos="linux"; goarch="amd64"; archive_extension="tar.gz"; binary_name="sing-box"
    ;;
  linux-arm64)
    goos="linux"; goarch="arm64"; archive_extension="tar.gz"; binary_name="sing-box"
    ;;
  windows-amd64)
    goos="windows"; goarch="amd64"; archive_extension="zip"; binary_name="sing-box.exe"
    ;;
  *)
    usage
    exit 2
    ;;
esac

for command_name in git go jq; do
  command -v "$command_name" >/dev/null 2>&1 || {
    echo "Required command is missing: $command_name" >&2
    exit 1
  }
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_root="$repo_root/.work/$target"
dist_root="$repo_root/dist"
source_root="$work_root/source"
package_root="$work_root/package"
tag_name="${upstream_ref#refs/tags/}"

if ! git ls-remote --exit-code --tags "$upstream_repo" "refs/tags/$tag_name" >/dev/null; then
  echo "Exact upstream tag does not exist: $tag_name" >&2
  exit 1
fi

rm -rf "$work_root"
mkdir -p "$source_root" "$package_root" "$dist_root"
git clone --depth 1 --branch "$tag_name" "$upstream_repo" "$source_root"

version="${tag_name#v}"
build_tags="$(tr -d '\r\n[:space:]' <"$source_root/release/DEFAULT_BUILD_TAGS_OTHERS")"
case ",$build_tags," in
  *,with_v2ray_api,*) ;;
  *) build_tags="${build_tags},with_v2ray_api" ;;
esac

source_commit="$(git -C "$source_root" rev-parse HEAD)"
upstream_ldflags="$(tr -d '\r\n' <"$source_root/release/LDFLAGS")"
artifact_base="sing-box-${version}-cx.${build_revision}-${goos}-${goarch}"
binary_path="$package_root/$binary_name"

(
  cd "$source_root"
  CGO_ENABLED=0 GOOS="$goos" GOARCH="$goarch" \
    go build -trimpath \
    -tags "$build_tags" \
    -ldflags "-s -w -buildid= ${upstream_ldflags} -X github.com/sagernet/sing-box/constant.Version=${version}-cx.${build_revision}" \
    -o "$binary_path" \
    ./cmd/sing-box
)

build_info="$(go version -m "$binary_path")"
grep -q "with_v2ray_api" <<<"$build_info" || {
  echo "Built binary does not report with_v2ray_api." >&2
  exit 1
}

compiler_go_version="$(head -n 1 <<<"$build_info" | awk '{print $NF}')"
builder_go_version="$(go version)"
metadata_path="$package_root/BUILD-METADATA.json"

jq -n \
  --arg upstreamRepository "$upstream_repo" \
  --arg upstreamRef "$tag_name" \
  --arg upstreamCommit "$source_commit" \
  --arg version "$version" \
  --arg buildRevision "$build_revision" \
  --arg compilerGoVersion "$compiler_go_version" \
  --arg builderGoVersion "$builder_go_version" \
  --arg targetOs "$goos" \
  --arg targetArch "$goarch" \
  --arg upstreamLdflags "$upstream_ldflags" \
  --arg buildTags "$build_tags" \
  '{
    schemaVersion: 1,
    core: "sing-box",
    upstreamRepository: $upstreamRepository,
    upstreamRef: $upstreamRef,
    upstreamCommit: $upstreamCommit,
    version: $version,
    buildRevision: ($buildRevision | tonumber),
    compilerGoVersion: $compilerGoVersion,
    builderGoVersion: $builderGoVersion,
    target: { os: $targetOs, arch: $targetArch },
    cgoEnabled: false,
    upstreamLdflags: $upstreamLdflags,
    buildTags: ($buildTags | split(","))
  }' >"$metadata_path"

archive_path="$dist_root/$artifact_base.$archive_extension"
if [[ "$archive_extension" == "zip" ]]; then
  command -v zip >/dev/null 2>&1 || { echo "Required command is missing: zip" >&2; exit 1; }
  (cd "$package_root" && zip -q -9 "$archive_path" "$binary_name" BUILD-METADATA.json)
else
  tar -C "$package_root" -czf "$archive_path" "$binary_name" BUILD-METADATA.json
fi

cp "$metadata_path" "$dist_root/$artifact_base.metadata.json"
(cd "$dist_root" && sha256sum "$(basename "$archive_path")" >"$artifact_base.sha256")

echo "Built $archive_path"
echo "$build_info"
