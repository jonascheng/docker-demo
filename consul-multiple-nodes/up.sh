#!/bin/bash

OS="$(uname -s)"

case "${OS}" in
    Darwin*)    HOSTIP=`ipconfig getifaddr en0` docker-compose --env-file ./config/server1.env up;;
    *)          HOSTIP=`hostname --ip-address` docker-compose --env-file ./config/server1.env up;;
esac

