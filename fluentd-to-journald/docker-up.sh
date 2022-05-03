#!/bin/bash

docker rm -f `docker ps -qa`
rm -rf fluentd/data
mkdir -p fluentd/data
chmod a+w -R fluentd/data

docker-compose -f docker-compose.yml up $@
