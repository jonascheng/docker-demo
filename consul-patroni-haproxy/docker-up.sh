#!/bin/bash

OS="$(uname -s)"

docker rm -f `docker ps -qa`

sudo mkdir -p /home/vagrant/postgresql/data/
# change owner to postgres for timescaledb
sudo chown -R 70:70 /home/vagrant/postgresql/
sudo chmod -R 750 /home/vagrant/postgresql/

case "${OS}" in
    Darwin*)    HOSTIP=`ipconfig getifaddr en0` docker-compose up $@;;
    *)          HOSTIP=`hostname --ip-address` docker-compose up $@;;
esac
