#!/bin/bash

#####
docker-compose down

docker volume prune -f >&2 >/dev/null
