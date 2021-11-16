#/bin/bash

DOCKER_IMAGE=pgbench
DB_HOST=10.1.0.10
DB_PORT=15432
DB_USER=postgres
DB_PWD=supersecret

# build docker image
docker build -t ${DOCKER_IMAGE} .

# create database
docker run -it \
 ${DOCKER_IMAGE} sh -c "psql postgresql://${DB_USER}:${DB_PWD}@${DB_HOST}:${DB_PORT}"
