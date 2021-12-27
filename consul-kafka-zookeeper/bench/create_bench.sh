#/bin/bash

DOCKER_IMAGE=docker.io/bitnami/kafka:2.5.0-debian-10-r112
KAFKA_HOST=10.1.0.10
KAFKA_PORT=19092
KAFKA_BENCH=${KAFKA_BENCH:-"my-topic"}

echo create topic ${KAFKA_BENCH}

# create topic
docker run -v `pwd`/../:/opt/bitnami/kafka/conf \
 -t ${DOCKER_IMAGE} sh -c "kafka-topics.sh --create --bootstrap-server ${KAFKA_HOST}:${KAFKA_PORT} --topic ${KAFKA_BENCH} --replication-factor 3 --partitions 13 --command-config /opt/bitnami/kafka/conf/kafka-client/client.properties"
