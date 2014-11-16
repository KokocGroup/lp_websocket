package main

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
	"net/url"
	"redis"
	"time"
	"fmt"
)

const (
	REDIS_HOST  = "127.0.0.1"
	REDIS_PORT  = 6379
	REDIS_PASS = ""
	REDIS_DB = 0

	QUEUE_NAME = "events"
	RETRY_AFTER = 180
	MAX_RETRIES = 3
)

func sendEvent(event_json []byte) {
	var event map[string]interface{}
	retries := 0

	if err := json.Unmarshal(event_json, &event); err != nil {
		fmt.Println("JSON Error: ", err)
		return
	}

	eventUrl := event["url"]
	eventMessage := event["message"]
	eventApiKey := event["api_key"]

	if eventUrl != nil && eventMessage != nil && eventApiKey != nil {

		params := url.Values{}
		params.Add("apiKey", eventApiKey.(string))
		params.Add("event", eventMessage.(string))
send:
		resp, err := http.PostForm(eventUrl.(string), params)
		if err != nil {
			fmt.Println("Error: ", err, retries)
			time.Sleep(RETRY_AFTER * time.Second)
			retries += 1
			if retries < MAX_RETRIES {
				goto send
			}
		} else {
			ioutil.ReadAll(resp.Body)
			//fmt.Println(string(b))
			resp.Body.Close()
		}
	}
}


func main() {
server:
	spec := redis.DefaultSpec()
	spec.Host(REDIS_HOST).Port(REDIS_PORT)
	spec.Db(REDIS_DB).Password(REDIS_PASS)

	client, e := redis.NewSynchClientWithSpec(spec)
	if e != nil {
		fmt.Println("Error creating client for worker: ", e)
		time.Sleep(5 * time.Second)
		goto server
	}

	defer client.Quit()

	var res [][]byte
	var err redis.Error

	for {
		res, err = client.Brpop(QUEUE_NAME, 0)

		if err != nil {
			fmt.Println("Error: ", err)
			time.Sleep(5 * time.Second)
			goto server
		}

		if res != nil {
			go sendEvent(res[1])
		}
	}
}
