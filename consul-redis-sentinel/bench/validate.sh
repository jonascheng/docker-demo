#/bin/bash

DOCKER_IMAGE=bench
REDIS_HOST=10.1.0.10
REDIS_PORT=6379
REDIS_PWD=supersecret

# build docker image
docker build -t ${DOCKER_IMAGE} .

#####
for REDIS_HOST in 10.1.0.10 10.1.0.20 10.1.0.30
do
    echo ${REDIS_HOST}: DBSIZE
    # connect database
    docker run -it \
    ${DOCKER_IMAGE} sh -c "redis-cli --no-auth-warning -u redis://${REDIS_PWD}@${REDIS_HOST}:${REDIS_PORT}/0 DBSIZE"
done
