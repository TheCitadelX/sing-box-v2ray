# Architecture

The manually-triggered GitHub Actions workflow validates an exact `SagerNet/sing-box` tag, builds a small
target matrix with upstream server tags plus `with_v2ray_api`, verifies Go build metadata, and publishes an
immutable-by-workflow release.

Release archives contain the binary and `BUILD-METADATA.json`. Release-level files include `SHA256SUMS`,
`release-manifest.json`, and GitHub provenance attestations.
