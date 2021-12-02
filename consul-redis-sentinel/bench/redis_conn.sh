#/bin/bash

DOCKER_IMAGE=bench
REDIS_HOST=10.1.0.10
REDIS_PORT=16379
REDIS_PWD=supersecret

# build docker image
docker build -t ${DOCKER_IMAGE} .

# connect database
docker run -it \
 ${DOCKER_IMAGE} sh -c "redis-cli --no-auth-warning -u redis://${REDIS_PWD}@${REDIS_HOST}:${REDIS_PORT}/0"
