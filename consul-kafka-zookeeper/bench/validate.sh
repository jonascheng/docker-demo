#/bin/bash

DOCKER_IMAGE=docker.io/bitnami/kafka:2.5.0-debian-10-r112
KAFKA_HOST=10.1.0.10
KAFKA_PORT=19092
KAFKA_BENCH=my-topic

BENCH_RECORDS=${BENCH_RECORDS:-100000}
BENCH_BYTES=${BENCH_BYTES:-1000}

echo ${BENCH_RECORDS} records
echo ${BENCH_BYTES} bytes payload

# #####
# for KAFKA_HOST in 10.1.0.10 10.1.0.20 10.1.0.30
# do
#     echo ${KAFKA_HOST}: DBSIZE
#     # connect database
#     docker run -it \
#     ${DOCKER_IMAGE} sh -c "redis-cli --no-auth-warning -u redis://${KAFKA_PWD}@${KAFKA_HOST}:${KAFKA_PORT}/0 DBSIZE"
# done

# --broker-list <String: hostname:        REQUIRED: The list of hostname and
#   port,...,hostname:port>                 port of the server to connect to.
# --topic-white-list <String: Java regex  White list of topics to verify replica
#   (String)>                               consistency. Defaults to all topics.
#                                           (default: .*)

docker run -v `pwd`/../:/opt/bitnami/kafka/conf -it \
 ${DOCKER_IMAGE} sh -c "kafka-replica-verification.sh --broker-list 10.1.0.10:9092,10.1.0.20:9092,10.1.0.30:9092 --topic-white-list ${KAFKA_BENCH} --consumer.config /opt/bitnami/kafka/conf/kafka-client/client.properties"
