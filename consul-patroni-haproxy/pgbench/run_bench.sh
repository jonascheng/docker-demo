#/bin/bash

DOCKER_IMAGE=pgbench
DB_HOST=10.1.0.10
DB_PORT=15432
DB_USER=postgres
DB_PWD=supersecret
DB_BENCH=pgbench
BENCH_CLIENTS=100
BENCH_TIME_SEC=10

# build docker image
docker build -t ${DOCKER_IMAGE} .

# run bench for ${BENCH_TIME_SEC} seconds with ${BENCH_CLIENTS} clients
docker run -it \
 ${DOCKER_IMAGE} sh -c "pgbench postgresql://${DB_USER}:${DB_PWD}@${DB_HOST}:${DB_PORT}/${DB_BENCH} -c ${BENCH_CLIENTS} -b tpcb-like -T ${BENCH_TIME_SEC}"
