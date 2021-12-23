#/bin/bash

DOCKER_IMAGE=bench
KAFKA_HOST=10.1.0.10
KAFKA_PORT=19092
KAFKA_PWD=supersecret

# build docker image
docker build -t ${DOCKER_IMAGE} .

# connect database
docker run -it \
 ${DOCKER_IMAGE} sh -c "redis-cli --no-auth-warning -u redis://${KAFKA_PWD}@${KAFKA_HOST}:${KAFKA_PORT}/0"
