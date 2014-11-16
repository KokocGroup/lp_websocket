package main

import (
	"encoding/json"
	"io/ioutil"
	"os/signal"
	"net/http"
	"net/url"
	"syscall"
	"redis"
	"sync"
	"time"
	"fmt"
	"os"
)

const (
	REDIS_HOST = "127.0.0.1"
	REDIS_PORT = 6379
	REDIS_PASS = ""
	REDIS_DB   = 0

	QUEUE_NAME  = "events"
	RETRY_AFTER = 60
	MAX_RETRIES = 3
)

var wg sync.WaitGroup

func sendEvent(event_json []byte) {
	var event map[string]interface{}
	retries := 0

	if err := json.Unmarshal(event_json, &event); err != nil {
		fmt.Println("JSON Error: ", err)
		wg.Done()
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
	wg.Done()
}


func main() {
	exitReceived := false
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)
	signal.Notify(c, syscall.SIGTERM)
	signal.Notify(c, syscall.SIGKILL)
	signal.Notify(c, syscall.SIGQUIT)
	go func() {
		<-c
		fmt.Println("Restart now")
		exitReceived = true
		wg.Wait()
		os.Exit(1)
	}()

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
			wg.Add(1)
			go sendEvent(res[1])
		}

		if exitReceived == true {
			wg.Wait()
			break
		}
	}
}
