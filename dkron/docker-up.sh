#!/bin/bash

OS="$(uname -s)"

docker rm -f `docker ps -qa`

case "${OS}" in
    Darwin*)    HOSTIP=`ipconfig getifaddr en0`;;
    *)          HOSTIP=`hostname --ip-address`;;
esac

HOSTNAME=`hostname`

HOSTIP=${HOSTIP} HOSTNAME=${HOSTNAME} docker-compose up $@
