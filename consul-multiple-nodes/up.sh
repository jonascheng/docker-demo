#!/bin/bash

OS="$(uname -s)"

case "${OS}" in
    Darwin*)    HOSTIP=`ipconfig getifaddr en0` docker-compose --env-file ./config/server.env up;;
    *)          HOSTIP=`hostname --ip-address` docker-compose --env-file ./config/server.env up;;
esac
