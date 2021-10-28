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
vagrant@server1:/vagrant$ ./up.sh
```

## Testing procedure

1. Create topic on one of kafka node

```console
vagrant@server1:/vagrant$ docker exec -it kafka sh -c "kafka-topics.sh --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 13 --topic my-topic"
```

2. Publish message on one of kafka node

```console
vagrant@server2:/vagrant$ docker exec -it kafka sh -c "kafka-console-producer.sh \
    --broker-list localhost:9092 \
    --topic my-topic"
```

3. List messgae on one of kafka node

```console
vagrant@server3:/vagrant$ docker exec -it kafka sh -c "kafka-console-consumer.sh \
    --bootstrap-server localhost:9092 \
    --topic my-topic \
    --from-beginning"
```

# References

* [Getting started with Kafka tutorial](http://cloudurable.com/blog/kafka-tutorial-kafka-from-command-line/index.html)
