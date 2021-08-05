package main

import (
	"fmt"
	"os"
	"strconv"

	"github.com/go-redis/redis"
)

// getEnv get key environment variable if exist otherwise return defalutValue
func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if len(value) == 0 {
		return defaultValue
	}
	return value
}

func newRedisClient() *redis.Client { // init redis.Client and return the reference
	var redisServer string = getEnv("REDIS_SERVER", "localhost")

	client := redis.NewClient(&redis.Options{
		Addr:     redisServer + ":6379",
		Password: "", // no password set
		DB:       0,  // use default DB
	})

	pong, err := client.Ping().Result()
	fmt.Println(pong, err)
	return client
}

func process_message(msg redis.XMessage) bool {
	var processMessage string = getEnv("PROCESS_MSG", "even")

	for k, v := range msg.Values {
		fmt.Printf("key: %s, value: %s\n", k, v)
	}

	var counterStr string = msg.Values["counter"].(string)
	counterInt, _ := strconv.ParseInt(counterStr, 10, 32)
	isEven := counterInt%2 == 0
	if processMessage == "even" && isEven {
		fmt.Println("processed msg id:", msg.ID)
		return true
	} else if processMessage == "odd" && !isEven {
		fmt.Println("processed msg id:", msg.ID)
		return true
	}
	fmt.Println("skip msg id:", msg.ID)
	return false
}

func consume(c *redis.Client) { // operate with redis.Client
	var streamName string = getEnv("STREAM_NAME", "stream")
	const consumerGroupName string = "group"
	const consumerName string = "consumer"

	// create consumer group
	err := c.XGroupCreate(streamName, consumerGroupName, "0-0").Err()
	if err != nil && err.Error() != "BUSYGROUP Consumer Group name already exists" {
		panic(err)
	}

	// return pending entries: messages delivered to it, but not yet acknowledged.
	entries, err := c.XReadGroup(&redis.XReadGroupArgs{
		Streams:  []string{streamName, "0"},
		Group:    consumerGroupName,
		Consumer: consumerName,
		NoAck:    false,
	}).Result()
	if err != nil {
		panic(err)
	}
	fmt.Println("res:", entries[0].Stream)
	fmt.Printf("Messages: %T\n", entries[0].Messages)

	// process pending messages
	for id, values := range entries[0].Messages {
		fmt.Println("msg id:", id)
		fmt.Printf("msg: %T\n", values)
		processed := process_message(values)
		if processed {
			// ack message
			err := c.XAck(streamName, consumerGroupName, values.ID).Err()
			if err != nil {
				panic(err)
			}
		}
	}

	for {
		entries, err = c.XReadGroup(&redis.XReadGroupArgs{
			// The special > ID, which means that the consumer want to receive only
			// messages that were never delivered to any other consumer.
			// It just means, give me new messages.
			Streams:  []string{streamName, ">"},
			Group:    consumerGroupName,
			Consumer: consumerName,
			Count:    10,
			// Block:    100 * time.Millisecond,
			NoAck: false,
		}).Result()
		if err != nil {
			panic(err)
		}
		fmt.Println("res:", entries)

		// process delivered messages
		for id, values := range entries[0].Messages {
			fmt.Println("msg id:", id)
			fmt.Printf("msg: %T\n", values)
			processed := process_message(values)
			if processed {
				// ack message
				err := c.XAck(streamName, consumerGroupName, values.ID).Err()
				if err != nil {
					panic(err)
				}
			}
		}
	}
}

func main() {
	c := newRedisClient()
	consume(c)
}
