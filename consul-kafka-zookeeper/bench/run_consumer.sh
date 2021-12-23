#/bin/bash

DOCKER_IMAGE=docker.io/bitnami/kafka:2.5.0-debian-10-r112
KAFKA_HOST=10.1.0.10
KAFKA_PORT=19092
KAFKA_BENCH=my-topic

BENCH_RECORDS=${BENCH_RECORDS:-100000}
BENCH_BYTES=${BENCH_BYTES:-1000}

echo ${BENCH_RECORDS} records
echo ${BENCH_BYTES} bytes payload

# --bootstrap-server <String: server to    REQUIRED unless --broker-list
#   connect to>                              (deprecated) is specified. The server
#                                            (s) to connect to.
# --consumer.config <String: config file>  Consumer config properties file.
# --messages <Long: count>                 REQUIRED: The number of messages to
#                                            send or consume
# --num-fetch-threads <Integer: count>     Number of fetcher threads. (default: 1)
# --threads <Integer: count>               Number of processing threads.
#                                            (default: 10)
# --topic <String: topic>                  REQUIRED: The topic to consume from.
# --print-metrics                          Print out the metrics.

docker run -v `pwd`/../:/opt/bitnami/kafka/conf -it \
 ${DOCKER_IMAGE} sh -c "kafka-consumer-perf-test.sh --bootstrap-server=${KAFKA_HOST}:${KAFKA_PORT} --topic ${KAFKA_BENCH} --messages ${BENCH_RECORDS} --threads=10 --consumer.config /opt/bitnami/kafka/conf/kafka-client/client.properties"
