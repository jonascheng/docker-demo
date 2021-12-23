#/bin/bash

DOCKER_IMAGE=bench
REDIS_HOST=10.1.0.10
REDIS_PORT=16379
REDIS_PWD=supersecret

# build docker image
docker build -t ${DOCKER_IMAGE} .

docker run -it \
 -e REDIS_HOST=${REDIS_HOST} \
 -e REDIS_PORT=${REDIS_PORT} \
 -e REDIS_PWD=${REDIS_PWD} \
 ${DOCKER_IMAGE} redis-benchmark $@
