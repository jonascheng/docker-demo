## Overview

Deploy a Consul datacenter, and an sentinel-enabled redis service. These resources will be used to provide complete service mesh and redis high availability capabilities.

To prevent from confusing from redis cluster, avoid to use term - redis cluster.

## Prerequisites

- Vagrant
- VirtualBox
- Linux or OSX

## Architecture

![](images/redis-cluster.png)

## Deployment procedure

1. Clone [docker-demo](https://github.com/jonascheng/docker-demo) repository.
2. Navigate to this directory.
3. `vagrant up` to provision three servers, which are `server1`, `server2` and `server3` respectively.
4. Execute the following commands in three servers

```console
$> vagrant ssh server1
vagrant@server1:~$ cd /vagrant
vagrant@server1:/vagrant$ ./docker-up.sh
```

## Testing procedure

1. Create topic on one of kafka node

```console
vagrant@server1:/vagrant$ docker exec -it stateless sh -c "kafka-topics.sh \
    --create --bootstrap-server kafka-proxy:9092 \
    --replication-factor 3 \
    --partitions 13 \
    --topic my-topic \
    --command-config /tmp/kafka-client/client.properties"
```

2. Publish message on one of kafka node

```console
vagrant@server2:/vagrant$ docker exec -it stateless sh -c "kafka-console-producer.sh \
    --broker-list kafka-proxy:9092 \
    --topic my-topic \
    --producer.config /tmp/kafka-client/client.properties"
```

3. List messgae on one of kafka node

```console
vagrant@server3:/vagrant$ docker exec -it stateless sh -c "kafka-console-consumer.sh \
    --bootstrap-server kafka-proxy:9092 \
    --topic my-topic \
    --from-beginning \
    --consumer.config /tmp/kafka-client/client.properties"
```

### Bench flow

![](images/tbd.png)

#### What's victim command?

These are commands executed randomly to simulate disaster.
* docker restart kafka
* docker restart zookeeper
* docker restart consul-server
* docker stop kafka, and start after pause
* docker stop zookeeper, and start after pause
* docker stop consul-server and start after pause
* docker compose restart
* docker compose stop and up after pause
* systemctl restart docker
* systemctl stop docker and start after pause

#### How to validate?

1. Only validate after "Run Bench", and wait a while to make sure database in sync
2. Connect to each kafka service via port 9092
3. Execute command to check key counts
4. Expect equal count from all kafka services

### Bench procedure

1. Clean up docker persistent data

   Execute the following commands in first three servers

```console
$> vagrant ssh server1
vagrant@server1:~$ cd /vagrant
vagrant@server1:~$ ./docker-cleanup.sh
```

2. Build docker images for the cluster

   Execute the following commands in first three servers

```console
# login your docker account if you encounter any throttle problem
$> vagrant ssh server1
vagrant@server1:~$ cd /vagrant
vagrant@server1:~$ ./docker-build.sh
```

3. Start benchmark stability

  Execute the following commands in server-bench

```console
$> vagrant ssh server-bench
vagrant@server1:~$ cd /vagrant/bench
vagrant@server1:~$ go run main.go
```

4. Once the program stop it will be log in `/tmp/bench-*.log`, please check if any exception or error in log.

# References

* [Getting started with Kafka tutorial](http://cloudurable.com/blog/kafka-tutorial-kafka-from-command-line/index.html)
* [Enable Security For Kafka And Zookeeper](https://docs.bitnami.com/kubernetes/infrastructure/kafka/administration/enable-security/)
