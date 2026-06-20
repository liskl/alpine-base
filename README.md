# Docker Alpine 3.x: Base

Base image used as the foundation for any images moving forward from the Dev-Ops team.

The image is built `FROM scratch` and is populated by extracting an Alpine Linux
minimal root filesystem (`minirootfs`) tarball directly into `/`. This keeps the
resulting image as small as possible while still providing a full Alpine userland
(including `apk`, the Alpine package manager).

## Current Version

| Setting          | Value     |
| ---------------- | --------- |
| Alpine release   | `3.24.1`  |
| `alpine_version` | `3.24`    |
| Architecture     | `x86_64`  |
| Root filesystem  | `alpine3.24-rootfs.tar.gz` |

## Implementation

The build is intentionally minimal. The [`Dockerfile`](./Dockerfile) does the
following:

1. Starts `FROM scratch` (an empty image with no parent layers).
2. Defines an `alpine_version` environment variable that selects which bundled
   root filesystem tarball is used.
3. Uses `ADD` to unpack `alpine${alpine_version}-rootfs.tar.gz` into `/`. Docker
   automatically extracts local `.tar.gz` archives passed to `ADD`, so the
   contents of the Alpine `minirootfs` become the image's root filesystem.

```dockerfile
FROM scratch

# DevOps Team
LABEL org.opencontainers.image.authors="Loren Lisk <loren.lisk@liskl.com>"

ENV alpine_version=3.24

ADD alpine${alpine_version}-rootfs.tar.gz /
```

The repository keeps the root filesystem tarballs for several Alpine releases so
older images can still be reproduced:

- `alpine3.3-rootfs.tar.gz`
- `alpine3.4-rootfs.tar.gz`
- `alpine3.5-rootfs.tar.gz`
- `alpine3.24-rootfs.tar.gz` (current)

## Building

```bash
docker build -t alpine-base:3.24 .
```

To build an older revision, override the version argument by editing the
`alpine_version` value in the `Dockerfile` (the tarball for that release must be
present in the repository).

## Verifying the Image

```bash
docker run --rm alpine-base:3.24 cat /etc/alpine-release
# 3.24.1
```

## Updating to a Newer Alpine Release

The bundled root filesystem comes from the official Alpine `minirootfs`
downloads. To bump to a new release:

1. Find the desired release on the Alpine CDN, for example:
   <https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/x86_64/>
2. Download the `minirootfs` tarball and store it in this repository using the
   `alpine<major.minor>-rootfs.tar.gz` naming convention:

   ```bash
   curl -o alpine3.24-rootfs.tar.gz \
     https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/x86_64/alpine-minirootfs-3.24.1-x86_64.tar.gz
   ```

3. Verify the download against the published checksum:

   ```bash
   curl https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/x86_64/alpine-minirootfs-3.24.1-x86_64.tar.gz.sha256
   echo "<expected-sha256>  alpine3.24-rootfs.tar.gz" | sha256sum -c -
   ```

4. Update the `alpine_version` value in the [`Dockerfile`](./Dockerfile) to match
   the new `<major.minor>` and update this `README`.

## Continuous Publishing (GHCR)

This repository automatically builds the image and publishes it to the GitHub
Container Registry (GHCR) via the
[`Publish image to GHCR`](./.github/workflows/publish.yml) GitHub Actions
workflow.

The published image is available at:

```
ghcr.io/<owner>/<repo>
```

### When it runs

| Event                         | Behaviour                          |
| ----------------------------- | ---------------------------------- |
| Push to `master`              | Build **and push** (`latest` + version tags) |
| Push of a `v*` tag            | Build **and push** (tag-named image) |
| Pull request targeting `master` | Build **only** (no push), as a CI check |
| Manual `workflow_dispatch`    | Build **and push**                 |

### Image tags

The workflow tags images using:

- The Alpine version read directly from the `alpine_version` line in the
  `Dockerfile` (e.g. `3.24`).
- `latest`, when building from the default branch (`master`).
- The git tag name, for `v*` tag pushes.
- A short commit SHA (e.g. `sha-abc1234`).

### Authentication

Pushes authenticate with the built-in `GITHUB_TOKEN`; no additional secrets are
required. The workflow requests `packages: write` permission so it can publish to
GHCR. The first publish creates the package; make it public (or grant access)
from the repository's *Packages* settings if external pulls are required.

### Pulling the image

```bash
docker pull ghcr.io/<owner>/<repo>:latest
```
