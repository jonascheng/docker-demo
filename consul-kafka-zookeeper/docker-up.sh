#!/bin/bash

KAFKA_MEM_LIMITS=${KAFKA_MEM_LIMITS:-100M}

OS="$(uname -s)"

docker rm -f `docker ps -qa`

case "${OS}" in
    Darwin*)    HOSTIP=`ipconfig getifaddr en0`;;
    *)          HOSTIP=`hostname --ip-address`;;
esac

case "${HOSTIP}" in
    10.1.0.10*) KAFKA_MEM_LIMITS=${KAFKA_MEM_LIMITS} HOSTIP=${HOSTIP} KAFKA_BROKER_ID=1 ZOO_SERVER_ID=1 ZOO_SERVERS=0.0.0.0:2888:3888,10.1.0.20:2888:3888,10.1.0.30:2888:3888 docker-compose up $@;;
    10.1.0.20*) KAFKA_MEM_LIMITS=${KAFKA_MEM_LIMITS} HOSTIP=${HOSTIP} KAFKA_BROKER_ID=2 ZOO_SERVER_ID=2 ZOO_SERVERS=10.1.0.10:2888:3888,0.0.0.0:2888:3888,10.1.0.30:2888:3888 docker-compose up $@;;
    *)          KAFKA_MEM_LIMITS=${KAFKA_MEM_LIMITS} HOSTIP=${HOSTIP} KAFKA_BROKER_ID=3 ZOO_SERVER_ID=3 ZOO_SERVERS=10.1.0.10:2888:3888,10.1.0.20:2888:3888,0.0.0.0:2888:3888 docker-compose up $@;;
esac
