# sing-box with V2Ray API

Reproducible builds of exact [`SagerNet/sing-box`](https://github.com/SagerNet/sing-box) tags with
`with_v2ray_api` appended to the upstream server build tags.

Supported targets:

- Linux `amd64`
- Linux `arm64`
- Windows `amd64`

Run **Actions -> Build sing-box with V2Ray API -> Run workflow**, enter an exact upstream tag and a build
revision. Releases use the form `v1.13.13-cx.1` and are never overwritten by the workflow.

Each release includes archives, build metadata, SHA256 checksums, and a combined manifest. GitHub provenance
attestations are added when the repository visibility and organization plan support them.

## Local build

```bash
./scripts/build.sh v1.13.13 linux-amd64 1
```

Validate the extracted binary:

```bash
./sing-box check -c scripts/v2ray-api-smoke.json
```

## CitadelX

```json
{
  "CoreRepos": {
    "Singbox": {
      "Owner": "TheCitadelX",
      "Repo": "sing-box-v2ray"
    }
  }
}
```
