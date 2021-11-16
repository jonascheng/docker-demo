#/bin/bash

DOCKER_IMAGE=pgbench
DB_HOST=10.1.0.10
DB_PORT=15432
DB_USER=postgres
DB_PWD=supersecret
DB_BENCH=pgbench
BENCH_CLIENTS=100
BENCH_TIME_SEC=60
BENCH_TX_RATE_PER_SEC=100

# build docker image
docker build -t ${DOCKER_IMAGE} .

while true
do
    echo run bench for ${BENCH_TIME_SEC} seconds with ${BENCH_CLIENTS} clients and ${BENCH_TX_RATE_PER_SEC} tx per second
    docker run -it \
    ${DOCKER_IMAGE} sh -c "pgbench postgresql://${DB_USER}:${DB_PWD}@${DB_HOST}:${DB_PORT}/${DB_BENCH} --client=${BENCH_CLIENTS} --time=${BENCH_TIME_SEC} --rate=${BENCH_TX_RATE_PER_SEC} --builtin=tpcb-like"
done