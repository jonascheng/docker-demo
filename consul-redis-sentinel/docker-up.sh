#!/bin/bash

REDIS_MEM_LIMITS=${REDIS_MEM_LIMITS:-100M}

OS="$(uname -s)"

docker rm -f `docker ps -qa`

case "${OS}" in
    Darwin*)    HOSTIP=`ipconfig getifaddr en0`;;
    *)          HOSTIP=`hostname --ip-address`;;
esac

case "${HOSTIP}" in
    10.1.0.10*) REDIS_MEM_LIMITS=${REDIS_MEM_LIMITS} HOSTIP=${HOSTIP} REPLICATION=master docker-compose up $@;;
    *)          REDIS_MEM_LIMITS=${REDIS_MEM_LIMITS} HOSTIP=${HOSTIP} REPLICATION=slave  docker-compose up $@;;
esac
