#!/bin/bash

OS="$(uname -s)"

case "${OS}" in
    Darwin*)    HOSTIP=`ipconfig getifaddr en0` docker-compose restart;;
    *)          HOSTIP=`hostname --ip-address` docker-compose restart;;
esac
