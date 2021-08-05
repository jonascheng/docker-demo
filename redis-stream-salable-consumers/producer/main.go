package main

import (
	"fmt"
	"os"
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

func produce(c *redis.Client) { // operate with redis.Client
	var streamName string = getEnv("STREAM_NAME", "stream")
	var counter uint32 = 0

	for ; counter < 100; counter++ {
		id, err := c.XAdd(&redis.XAddArgs{
			Stream: streamName,
			Values: map[string]interface{}{"counter": counter, "field1": "value1", "field2": "value2"},
		}).Result()
		if err != nil {
			panic(err)
		}
		fmt.Println("produced message:", id)
		time.Sleep(time.Second)
	}

}

func main() {
	c := newRedisClient()
	produce(c)
}
