#/bin/bash

DOCKER_IMAGE=bench
REDIS_HOST=10.1.0.10
REDIS_PORT=16379
REDIS_PWD=supersecret
BENCH_CLIENTS=${BENCH_CLIENTS:-100}
BENCH_REQUESTS=${BENCH_REQUESTS:-10000}
BENCH_BYTES=${BENCH_BYTES:-1000}
BENCH_KEYSPACE=${BENCH_KEYSPACE:-1000}

echo ${BENCH_REQUESTS} requests
echo ${BENCH_CLIENTS} parallel clients
echo ${BENCH_BYTES} bytes payload
echo ${BENCH_KEYSPACE} random keys

# build docker image
docker build -t ${DOCKER_IMAGE} .

# -c <clients>       Number of parallel connections (default 50)
# -n <requests>      Total number of requests (default 10000)
# -d <size>          Data size of SET/GET value in bytes (default 3)
# -r <keyspacelen>   Use random keys for SET/GET/INCR, random values for SADD
#   Using this option the benchmark will expand the string __rand_int__
#   inside an argument with a 12 digits number in the specified range
#   from 0 to keyspacelen-1. The substitution changes every time a command
#   is executed. Default tests use this to hit random keys in the
#   specified range.
docker run -t \
 ${DOCKER_IMAGE} sh -c "redis-benchmark -h ${REDIS_HOST} -p ${REDIS_PORT} -a ${REDIS_PWD} -c ${BENCH_CLIENTS} -n ${BENCH_REQUESTS} -d ${BENCH_BYTES} -r ${BENCH_KEYSPACE}"
