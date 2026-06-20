# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Docker base image built `FROM scratch`. There is no application code. The image
is produced entirely by `ADD`-ing a bundled Alpine `minirootfs` tarball into `/`,
which Docker auto-extracts. The result is a minimal Alpine userland (with `apk`)
and nothing else.

## Key files

- `Dockerfile` — the entire build. A single `ENV alpine_version <major.minor>`
  line selects which `alpine<major.minor>-rootfs.tar.gz` gets unpacked.
- `alpine*-rootfs.tar.gz` — vendored Alpine root filesystems (3.3, 3.4, 3.5,
  3.24). Old tarballs are kept on purpose so prior images stay reproducible.
- `.github/workflows/publish.yml` — builds and publishes to GHCR.

## The version coupling (important)

The Alpine version lives in exactly one place: the `ENV alpine_version` line in
the `Dockerfile`. Everything else derives from it:

- `ADD alpine${alpine_version}-rootfs.tar.gz /` interpolates it to pick the tarball.
- The CI workflow greps that same line (`grep -oP '^ENV\s+alpine_version[=\s]+\K[0-9.]+'`)
  to compute the published image tag.

So bumping the version means: drop in a new `alpine<major.minor>-rootfs.tar.gz`,
change the single `ENV` line, and the corresponding tarball MUST already exist in
the repo or the build breaks. Keep the `ENV` line format intact (the CI grep is
anchored to `^ENV  alpine_version` and accepts either `=` or whitespace before
the value).

## Commands

```bash
# Build locally
docker build -t alpine-base:3.24 .

# Verify the resulting image's Alpine release
docker run --rm alpine-base:3.24 cat /etc/alpine-release

# Refresh / add a rootfs tarball (see README for the matching .sha256 check)
curl -o alpine3.24-rootfs.tar.gz \
  https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/x86_64/alpine-minirootfs-3.24.1-x86_64.tar.gz
```

## CI / publishing

`publish.yml` pushes to `ghcr.io/<owner>/<repo>` on push to `master`, on `v*`
tags, and on manual dispatch. Pull requests targeting `master` build only (no
push) as a CI check. Tags applied: the Alpine version from the Dockerfile,
`latest` (default branch only), the git tag (for `v*`), and a short commit SHA.
Auth uses the built-in `GITHUB_TOKEN`; no extra secrets needed.

Build platform is `linux/amd64` only; the vendored tarballs are `x86_64`.
