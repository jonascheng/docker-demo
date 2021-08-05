# build stage
FROM golang:1.16.6-alpine3.14 AS builder

LABEL stage=consumer-intermediate

ENV  GO111MODULE=on

ADD ./ /go/src/consumer

RUN cd /go/src/consumer && go build -mod vendor

# final stage
FROM alpine:3.14

COPY --from=builder /go/src/consumer/consumer ./

CMD ["./consumer"]
