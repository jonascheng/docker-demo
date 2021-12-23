#/bin/bash

DOCKER_IMAGE=bench
KAFKA_HOST=10.1.0.10
KAFKA_PORT=19092
KAFKA_PWD=supersecret

# build docker image
docker build -t ${DOCKER_IMAGE} .

docker run -it \
 -e KAFKA_HOST=${KAFKA_HOST} \
 -e KAFKA_PORT=${KAFKA_PORT} \
 -e KAFKA_PWD=${KAFKA_PWD} \
 ${DOCKER_IMAGE} redis-benchmark $@
