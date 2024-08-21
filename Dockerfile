# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_3

FROM alpine:3

RUN apk update \
    && apk add bash curl openssl

ENV DEBUG_LEVEL=0
ENV ACME_APP_DIR=/home/acme/app
ENV ACME_CONFIG_DIR=/home/acme/config
ENV ACME_CERT_KEEP_DIR=/home/acme/certs/keep
ENV ACME_CERT_INSTALL_DIR=/home/acme/certs/install

# fill in acme built-in env variables
ENV LE_WORKING_DIR=${ACME_APP_DIR}
ENV LE_CONFIG_HOME=${ACME_CONFIG_DIR}
ENV CERT_HOME=${ACME_CERT_KEEP_DIR}

RUN curl https://get.acme.sh | sh -s \
    && ln -s ${ACME_APP_DIR}/acme.sh /bin/acme \
    && crontab -l | sed 's#> /dev/null##' | crontab - \
    && acme --set-default-ca --server letsencrypt

COPY --chmod=755 ./entrypoint.sh /

RUN ln -s ${ACME_CERT_KEEP_DIR} /config
VOLUME ["/config"]

RUN ln -s ${ACME_CERT_INSTALL_DIR} /install
VOLUME ["/install"]

ENTRYPOINT ["/entrypoint.sh"]

CMD ["tail", "-f", "/dev/null"]

HEALTHCHECK  --interval=15m \
    --start-interval=5m \
    --start-period=5m \
    CMD pgrep /usr/sbin/crond || exit 1

