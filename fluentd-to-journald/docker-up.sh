#!/bin/bash

docker rm -f `docker ps -qa`
rm -rf fluentd/data

docker-compose -f fluentd/docker-compose.yml up $@

./wait-for-it.sh 127.0.0.1:24224 -t 60

docker-compose -f docker-compose.yml up $@
