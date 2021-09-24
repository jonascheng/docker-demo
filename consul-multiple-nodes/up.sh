#!/bin/bash

OS="$(uname -s)"

docker rm -f `docker ps -qa`

case "${OS}" in
    Darwin*)    HOSTIP=`ipconfig getifaddr en0` docker-compose up;;
    *)          HOSTIP=`hostname --ip-address` docker-compose up;;
esac
