FROM daspanel/alpine-base-edge
MAINTAINER Abner G Jacobsen - http://daspanel.com <admin@daspanel.com>

# Set default env variables
ENV \
    # Stop container initialization if error occurs in cont-init.d, fix-attrs.d script's
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \

    # Timezone
    TZ="UTC" \

    # S6 overlay version
    S6_OVERLAY_VERSION=v1.18.1.5 \

    # Minio settings
    MINIO_PATH=github.com/minio/minio \
    MINIO_REPO=https://github.com/minio/minio.git \
    MINIO_BRANCH=master \
    GOPATH=/usr/local \
    GO17VENDOREXPERIMENT=1

RUN set -ex \
    && apk add --no-cache --virtual .build-deps \
        bash gcc musl-dev openssl go git \

    && git clone \
        -b ${MINIO_BRANCH} \
        ${MINIO_REPO} \
        /usr/local/src/${MINIO_PATH} \
  
    && cd /usr/local/src/${MINIO_PATH} \
    && go build -o /usr/bin/minio \

    && apk del .build-deps \
    
    && rm -rf \
        /var/cache/apk/* \
        /usr/local/*
    

VOLUME ["/opt/daspanel/data", "/opt/daspanel/log"]

# Inject files in container file system
COPY rootfs /

# Expose ports for the minio service
EXPOSE 9000

