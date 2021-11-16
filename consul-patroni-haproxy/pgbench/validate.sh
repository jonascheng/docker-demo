#/bin/bash

DOCKER_IMAGE=pgbench
DB_HOST=10.1.0.10
DB_PORT=5432
DB_USER=postgres
DB_PWD=supersecret
DB_BENCH=pgbench

# build docker image
docker build -t ${DOCKER_IMAGE} .

#####
for DB_HOST in 10.1.0.10 10.1.0.20 10.1.0.30
do
    echo ${DB_HOST}: select count* from pgbench_history;
    docker run -it \
    ${DOCKER_IMAGE} sh -c "psql postgresql://${DB_USER}:${DB_PWD}@${DB_HOST}:${DB_PORT}/${DB_BENCH} -t -c 'select count(*) from pgbench_history;'"
done
