#!/bin/bash

docker rm -f `docker ps -qa`
rm -rf fluentd/data

docker-compose -f docker-compose.yml up $@
