# Background

A demo GO program to illustreate Redis STREAM capability

In this demo, there are 2 roles:

1. Producer

   This single instance gnerates fake message periodically, the content includes a increasing counter.

2. Consumer

   There are two consumers, one to process message with even counter, and another process odd counter. Once the message is processed, the consumer ACK the message otherwise skip it.

As the result, you can use Redis command to check all pending messages.

# Demo

Run docker-compose to start this demo

```console
docker-compose up
```

Run redis client to list pending messages

```console
$> docker run -it --network redis-stream-salable-consumers --rm redis redis-cli -h redis

redis:6379> XPENDING my-stream group - + 1000

 1) 1) "1628332047025-0"
    2) "consumer-172.21.0.5"
    3) (integer) 91
    4) (integer) 2
 2) 1) "1628332049030-0"
    2) "consumer-172.21.0.5"
    3) (integer) 91
    4) (integer) 2
 3) 1) "1628332051036-0"
    2) "consumer-172.21.0.5"
    3) (integer) 91
    4) (integer) 2
```