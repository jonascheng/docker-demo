#!/bin/bash

OS="$(uname -s)"

docker rm -f `docker ps -qa`

case "${OS}" in
    Darwin*)    HOSTIP=`ipconfig getifaddr en0`;;
    *)          HOSTIP=`hostname --ip-address`;;
esac

HOSTIP=${HOSTIP} docker-compose up $@
