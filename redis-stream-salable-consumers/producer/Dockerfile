# build stage
FROM golang:1.16.6-alpine3.14 AS builder

LABEL stage=producer-intermediate

ENV  GO111MODULE=on

ADD ./ /go/src/producer

RUN cd /go/src/producer && go build -mod vendor

# final stage
FROM alpine:3.14

COPY --from=builder /go/src/producer/producer ./

CMD ["./producer"]
