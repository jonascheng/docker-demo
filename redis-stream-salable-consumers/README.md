# Background

A demo GO program to illustreate consumer groups in Redis STREAM

A consumer group is a data structure within a Redis Stream. As shown in figure below, you can think about a consumer group as a collection of lists. Another thing to imagine is a list of items that are not consumed by any consumers — for our discussion, let’s call this an “unconsumed list.” As data arrives in the stream, it is immediately pushed to the unconsumed list.

![How a Redis Streams consumer group is structured.](https://images.idgesg.net/images/article/2018/11/redis-streams-2-figure-3-100780395-large.jpg)

The consumer group maintains a separate list for each consumer, typically with an application attached. In figure, our solution has N identical applications (App 1, App 2, …. App n) that read data via Consumer 1, Consumer 2, … Consumer n respectively.

When an app reads data using the XREADGROUP command, specific data entries are removed from the unconsumed list and pushed into the pending entries list that belongs to the respective consumer. Thus, no two consumers will consume the same data.

Finally, when the app notifies the stream with the XACK command, it will remove the item from the consumer’s pending entries list.

In this demo, there are 2 roles:

1. Producer

   This single instance gnerates fake message periodically, the content includes a increasing counter.

2. Consumer

   There are two consumers, one to process message with even counter, and another process odd counter. Once the message is processed, the consumer ACK the message otherwise skip it.

   As the result, you can use Redis command to check all pending messages in the midst of the demo.

   Within the process, there is also another go routine to check pending messages and pick up from there.

   Eventually, all messages are processed after demo.

# Demo

Run docker-compose to start this demo

```console
docker-compose up
```

Run redis client to list pending messages repeatedly

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

Eventually, all messages are processed after demo.

# References

* [How to use consumer groups in Redis Streams](https://www.infoworld.com/article/3321938/how-to-use-redis-streams.html)
*