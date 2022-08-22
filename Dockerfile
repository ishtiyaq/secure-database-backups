FROM alpine:3.15 AS base

RUN apk --update add \
        tzdata \
        bash \
        tar \
        pigz \
        coreutils \
        mysql-client \
        mariadb-connector-c \
        postgresql-client \
        openssl \
        logrotate \
    && rm -rf /var/cache/apk/* \
    && mkdir /backup \
    && chmod 755 /backup

COPY ./src/ /usr/local/bin
COPY ./logrotate.d/* /etc/logrotate.d/

CMD [ "run-cron" ]


FROM base AS test

COPY --from=trajano/alpine-libfaketime /faketime.so /lib/faketime.so
ENV LD_PRELOAD=/lib/faketime.so

RUN apk add shellcheck make \
    && mkdir -p /usr/src/secure-database-backups

COPY ./src/ /usr/src/secure-database-backups/src/
COPY ./test/ /usr/src/secure-database-backups/test/
COPY ./Makefile /usr/src/secure-database-backups

WORKDIR /usr/src/secure-database-backups

CMD [ "tail", "-f", "/dev/null" ]
