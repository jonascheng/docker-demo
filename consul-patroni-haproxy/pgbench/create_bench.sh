#/bin/bash

DOCKER_IMAGE=pgbench
DB_HOST=10.1.0.10
DB_PORT=15432
DB_USER=postgres
DB_PWD=supersecret
DB_BENCH=pgbench
BENCH_SCALE_FACTOR=100

# build docker image
docker build -t ${DOCKER_IMAGE} .

# create database
docker run -t \
 ${DOCKER_IMAGE} sh -c "psql postgresql://${DB_USER}:${DB_PWD}@${DB_HOST}:${DB_PORT} -c 'create database ${DB_BENCH};'"

# initial bench data
docker run -t \
 ${DOCKER_IMAGE} sh -c "pgbench postgresql://${DB_USER}:${DB_PWD}@${DB_HOST}:${DB_PORT}/${DB_BENCH} -i -s ${BENCH_SCALE_FACTOR}"
