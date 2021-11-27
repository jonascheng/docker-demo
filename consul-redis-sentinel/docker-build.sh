#!/bin/bash

OS="$(uname -s)"

case "${OS}" in
    Darwin*)    HOSTIP=`ipconfig getifaddr en0` docker-compose build;;
    *)          HOSTIP=`hostname --ip-address` docker-compose build;;
esac
