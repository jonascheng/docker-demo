#/bin/bash

DOCKER_IMAGE=docker.io/bitnami/kafka:2.5.0-debian-10-r112
KAFKA_HOST=10.1.0.10
KAFKA_PORT=19092
KAFKA_BENCH=${KAFKA_BENCH:-"my-topic"}

docker run -v `pwd`/../:/opt/bitnami/kafka/conf \
 -e KAFKA_HOST=${KAFKA_HOST} \
 -e KAFKA_PORT=${KAFKA_PORT} \
 -e KAFKA_BENCH=${KAFKA_BENCH} \
 -it ${DOCKER_IMAGE} sh