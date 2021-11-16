#/bin/bash

DOCKER_IMAGE=pgbench
DB_HOST=10.1.0.10
DB_PORT=15432
DB_USER=postgres
DB_PWD=supersecret

# build docker image
docker build -t ${DOCKER_IMAGE} .

docker run -it \
 -e DB_HOST=${DB_HOST} \
 -e DB_PORT=${DB_PORT} \
 -e DB_USER=${DB_USER} \
 -e DB_PWD=${DB_PWD} \
 ${DOCKER_IMAGE} pgbench $@
