package main

import (
	"fmt"
	"net"
	"os"
	"strconv"
	"time"

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

func getLocalIP() string {
	conn, err := net.Dial("udp", "8.8.8.8:8")
	if err != nil {
		panic(err)
	}
	defer conn.Close()
	localIP := conn.LocalAddr().(*net.UDPAddr).IP
	fmt.Println(localIP.String())
	return localIP.String()
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

func pending_checker(c *redis.Client, streamName string, consumerGroupName string, consumerName string) {

loop:

	// list pending messages
	pending, err := c.XPendingExt(&redis.XPendingExtArgs{
		Stream: streamName,
		Group:  consumerGroupName,
		Start:  "-",
		End:    "+",
		Count:  10,
	}).Result()
	if err != nil {
		panic(err)
	}
	fmt.Println("pending messages:", pending)

	var pending_messages []string
	for _, msg := range pending {
		pending_messages = append(pending_messages, msg.Id)
	}
	fmt.Println("pending message Ids:", pending_messages)

	if len(pending_messages) == 0 {
		goto loop
	}

	// re-claim pending messages
	entries, err := c.XClaim(&redis.XClaimArgs{
		Stream:   streamName,
		Group:    consumerGroupName,
		Consumer: consumerName,
		MinIdle:  60000, // ms
		Messages: pending_messages,
	}).Result()
	if err != nil {
		panic(err)
	}
	fmt.Printf("Messages: %T\n", entries)

	// process pending messages
	for _, msg := range entries {
		// fmt.Printf("msg type: %T\n", msg)
		processed := process_message(msg)
		if processed {
			// ack message
			err := c.XAck(streamName, consumerGroupName, msg.ID).Err()
			if err != nil {
				panic(err)
			}
		}
	}

	// pause
	time.Sleep(60 * time.Second)

	goto loop
}

func consume(c *redis.Client) { // operate with redis.Client
	var streamName string = getEnv("STREAM_NAME", "stream")
	var consumerGroupName string = "group"
	var consumerName string = "consumer-" + getLocalIP()

	// create consumer group
	err := c.XGroupCreate(streamName, consumerGroupName, "0-0").Err()
	if err != nil && err.Error() != "BUSYGROUP Consumer Group name already exists" {
		panic(err)
	}

	go pending_checker(c, streamName, consumerGroupName, consumerName)

	for {
		entries, err := c.XReadGroup(&redis.XReadGroupArgs{
			// The special > ID, which means that the consumer want to receive only
			// messages that were never delivered to any other consumer.
			// It just means, give me new messages.
			Streams:  []string{streamName, ">"},
			Group:    consumerGroupName,
			Consumer: consumerName,
			Count:    1,
			// Block:    100 * time.Millisecond,
			NoAck: false,
		}).Result()
		if err != nil {
			panic(err)
		}
		fmt.Println("res:", entries)

		// process delivered messages
		for _, msg := range entries[0].Messages {
			// fmt.Printf("msg type: %T\n", msg)
			processed := process_message(msg)
			if processed {
				// ack message
				err := c.XAck(streamName, consumerGroupName, msg.ID).Err()
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
