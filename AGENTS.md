# Agent Guide

This repository builds `SagerNet/sing-box` from exact upstream tags. Do not patch upstream source.

- Preserve `release/DEFAULT_BUILD_TAGS_OTHERS`.
- Preserve `release/LDFLAGS`.
- Append only `with_v2ray_api`.
- Never overwrite a release; increment `build_revision`.
- Keep `BUILD-METADATA.json` and SHA256 files mandatory. Provenance attestation is best-effort because
  GitHub may disable it for private repositories on the current organization plan.
- Verify the workflow with `actionlint` and an extracted binary with `scripts/v2ray-api-smoke.json`.
