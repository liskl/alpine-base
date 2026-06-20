FROM scratch

# DevOps Team
LABEL org.opencontainers.image.authors="Loren Lisk <loren.lisk@liskl.com>"

ENV alpine_version=3.24

ADD alpine${alpine_version}-rootfs.tar.gz /
