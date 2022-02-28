#!/bin/bash

OS="$(uname -s)"

case "${OS}" in
    Darwin*)    HOSTIP=`ipconfig getifaddr en0` docker-compose stop;;
    *)          HOSTIP=`hostname --ip-address` docker-compose stop;;
esac
