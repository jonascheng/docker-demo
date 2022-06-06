#!/bin/bash

docker rm -f `docker ps -qa`
sudo rm /var/log/journal/fluentd/*
# sudo mkdir -p /var/log/journal/fluentd/
# sudo rm -rf /tmp/logrotate/data
# sudo mkdir -p /tmp/logrotate/data

docker-compose -f docker-compose.yml build

sudo /usr/bin/timedatectl set-time 00:00:00

docker-compose -f docker-compose.yml up $@
