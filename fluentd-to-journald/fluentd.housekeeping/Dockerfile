FROM alpine:3.12

ENV TS_FORMAT "%Y-%m-%dT%H:%M:%S%z"

RUN set -x \
  && apk add --no-cache tini tzdata moreutils

COPY housekeeping.cronjob /etc/.housekeeping.cronjob
RUN chmod 0755 /etc/.housekeeping.cronjob
COPY entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh

VOLUME ["/var/log"]

ENTRYPOINT ["tini", "-g", "--"]
CMD ["/entrypoint.sh"]