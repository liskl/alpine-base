FROM scratch

# DevOps Team
MAINTAINER Loren Lisk <loren.lisk@tstllc.net>

ENV alpine_version 3.24

ADD alpine${alpine_version}-rootfs.tar.gz /
