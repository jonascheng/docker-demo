#!/bin/bash

docker-compose -f docker-compose.yml stop
docker-compose -f fluentd/docker-compose.yml stop
