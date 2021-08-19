#!/bin/bash
HOSTIP=`hostname --ip-address` docker-compose --env-file ./config/server1.env up

