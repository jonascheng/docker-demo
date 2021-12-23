#/bin/bash

DOCKER_IMAGE=bench
KAFKA_HOST=10.1.0.10
KAFKA_PORT=9092
KAFKA_PWD=supersecret

# build docker image
docker build -t ${DOCKER_IMAGE} .

#####
for KAFKA_HOST in 10.1.0.10 10.1.0.20 10.1.0.30
do
    echo ${KAFKA_HOST}: DBSIZE
    # connect database
    docker run -it \
    ${DOCKER_IMAGE} sh -c "redis-cli --no-auth-warning -u redis://${KAFKA_PWD}@${KAFKA_HOST}:${KAFKA_PORT}/0 DBSIZE"
done
