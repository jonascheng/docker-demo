#/bin/bash

DOCKER_IMAGE=docker.io/bitnami/kafka:2.5.0-debian-10-r112
KAFKA_HOST=10.1.0.10
KAFKA_PORT=9092
KAFKA_BENCH=${KAFKA_BENCH:-"my-topic"}

# 查询结果如下图所示，从图中可以看到，Kafka将所有Replica均匀分布到了整个集群，并且Leader也均匀分布
for KAFKA_HOST in 10.1.0.10 10.1.0.20 10.1.0.30
do
    echo ${DB_HOST}: describe topic ${KAFKA_BENCH}
    docker run -v `pwd`/../:/opt/bitnami/kafka/conf -t \
    ${DOCKER_IMAGE} sh -c "kafka-topics.sh --describe --bootstrap-server ${KAFKA_HOST}:${KAFKA_PORT} --topic ${KAFKA_BENCH} --command-config /opt/bitnami/kafka/conf/kafka-client/client.properties"
done

# validate count of messages in a Kafka Topic
for KAFKA_HOST in 10.1.0.10 10.1.0.20 10.1.0.30
do
    echo ${DB_HOST}: describe all groups
    docker run -v `pwd`/../:/opt/bitnami/kafka/conf -t \
    ${DOCKER_IMAGE} sh -c "kafka-run-class.sh kafka.admin.ConsumerGroupCommand --describe --all-groups --bootstrap-server ${KAFKA_HOST}:${KAFKA_PORT} --command-config /opt/bitnami/kafka/conf/kafka-client/client.properties"
done
