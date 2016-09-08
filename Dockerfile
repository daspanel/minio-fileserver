
FROM daspanel/alpine-base
MAINTAINER Abner G Jacobsen - http://daspanel.com <admin@daspanel.com>

ENV TZ="UTC"

# Stop container initialization if error occurs in cont-init.d fix-attrs.d script's
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

ENV MINIO_PATH github.com/minio/minio
ENV MINIO_REPO https://${MINIO_PATH}.git
ENV MINIO_BRANCH master

ENV GOPATH /usr/local
ENV GO15VENDOREXPERIMENT 1

RUN apk update && \
  apk add \
    build-base \
    go \
    git && \
  git clone \
    -b ${MINIO_BRANCH} \
    ${MINIO_REPO} \
    /usr/local/src/${MINIO_PATH} && \
  cd \
    /usr/local/src/${MINIO_PATH} && \
  go build \
    -o /usr/bin/minio && \
  apk del \
    build-base \
    go \
    git && \
  rm -rf \
    /var/cache/apk/* \
    /usr/local/*

VOLUME ["/opt/daspanel/data", "/opt/daspanel/log"]

# Inject files in container file system
COPY rootfs /

# Expose ports for the minio service
EXPOSE 9000

