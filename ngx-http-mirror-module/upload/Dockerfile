FROM golang:1.16.6-alpine3.14 as build-env

ENV GOOS linux

RUN apk add --no-cache git build-base && \
  echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
  echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
  echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

WORKDIR /go/src/
COPY . .

RUN go build ./main.go

FROM alpine:latest

RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2
RUN mkdir /server
RUN mkdir /server/data

WORKDIR /server

COPY --from=build-env /go/src/main /server/

EXPOSE 8083

CMD ["./main"]
