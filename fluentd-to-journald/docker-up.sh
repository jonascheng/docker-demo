#!/bin/bash

docker rm -f `docker ps -qa`
rm -rf /tmp/fluentd/data
mkdir -p /tmp/fluentd/data
#####
# create empty log purposely
touch /tmp/fluentd/data/info.log
touch /tmp/fluentd/data/error.log
touch /tmp/fluentd/data/fatal.log
#####
chmod a+w -R /tmp/fluentd/data

docker-compose -f docker-compose.yml build
docker-compose -f docker-compose.yml up $@
