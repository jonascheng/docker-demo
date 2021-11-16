FROM alpine:3.10.1 as builder

RUN apk add --no-cache postgresql==11.12-r0

FROM alpine:3.10.1

RUN apk add --no-cache libpq==11.12-r0 libedit==20190324.3.1-r0
COPY --from=builder /usr/bin/pgbench /usr/bin/pgbench
COPY --from=builder /usr/bin/psql /usr/bin/psql
