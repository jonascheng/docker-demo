#/bin/bash

DOCKER_IMAGE=docker.io/bitnami/kafka:2.5.0-debian-10-r112
KAFKA_HOST=10.1.0.10
KAFKA_PORT=19092
KAFKA_BENCH=my-topic

BENCH_RECORDS=${BENCH_RECORDS:-100000}
BENCH_BYTES=${BENCH_BYTES:-1000}

echo ${BENCH_RECORDS} records
echo ${BENCH_BYTES} bytes payload

#   --topic TOPIC          produce messages to this topic
#   --num-records NUM-RECORDS
#                          number of messages to produce
#   --throughput THROUGHPUT
#                          throttle    maximum    message    throughput    to
#                          *approximately* THROUGHPUT messages/sec.  Set this
#                          to -1 to disable throttling.
#   --producer-props PROP-NAME=PROP-VALUE [PROP-NAME=PROP-VALUE ...]
#                          kafka producer  related  configuration  properties
#                          like   bootstrap.servers,client.id    etc.   These
#                          configs take precedence over  those  passed via --
#                          producer.config.
#   --producer.config CONFIG-FILE
#                          producer config properties file.
#   --record-size RECORD-SIZE
#                          message size in bytes. Note  that you must provide
#                          exactly one of --record-size or --payload-file.

docker run -v `pwd`/../:/opt/bitnami/kafka/conf -it \
 ${DOCKER_IMAGE} sh -c "kafka-producer-perf-test.sh --producer-props bootstrap.servers=${KAFKA_HOST}:${KAFKA_PORT} --topic ${KAFKA_BENCH} --num-records ${BENCH_RECORDS} --record-size ${BENCH_BYTES} --throughput -1 --producer.config /opt/bitnami/kafka/conf/kafka-client/client.properties"
