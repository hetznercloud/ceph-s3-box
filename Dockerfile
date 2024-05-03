# syntax=docker/dockerfile:1
ARG IMAGE_PROXY=""
ARG DEBIAN_FRONTEND=noninteractive

FROM ${IMAGE_PROXY}ubuntu:24.04 AS ceph
ENV TZ=Etc/UTC

RUN apt -y update && apt -y install \
    lsb-release \
    wget \
    curl \
    pgp \
    tzdata \
    vim \
    dnsutils \
    iputils-ping \
    iproute2 \
    jq
RUN wget \
        -q \
        -O- https://download.ceph.com/keys/release.asc | \
        gpg --dearmor > /etc/apt/trusted.gpg.d/ceph.gpg && \
    echo "deb https://download.ceph.com/debian-reef/ $(lsb_release -sc) main" \
        > /etc/apt/sources.list.d/ceph.list && \
    apt -y update && \
    apt install -y ceph radosgw
RUN apt clean && \
    apt autoremove -y && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

FROM ceph as radosgw
ENV TZ=Etc/UTC
ENV ACCESS_KEY="radosgwadmin"
ENV SECRET_KEY="radosgwadmin"
ENV MGR_USERNAME="admin"
ENV MGR_PASSWORD="admin"
ENV MAIN="none"

EXPOSE 7480

COPY ./entrypoint.sh /entrypoint
ENTRYPOINT /entrypoint
