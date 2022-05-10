#!/bin/bash

docker rm -f `docker ps -qa`
sudo rm -rf /tmp/fluentd/data
sudo mkdir -p /tmp/fluentd/data
#####
# create empty log purposely
sudo touch /tmp/fluentd/data/info.log
sudo touch /tmp/fluentd/data/error.log
sudo touch /tmp/fluentd/data/fatal.log
#####
sudo chmod a+w -R /tmp/fluentd/data

docker-compose -f docker-compose.yml build
docker-compose -f docker-compose.yml up $@
