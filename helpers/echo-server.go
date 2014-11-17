package main

import (
	"io"
	"fmt"
	"strings"
	"net/http"
)

var counting int = 0

func HandlePost(w http.ResponseWriter, r *http.Request) {
	counting += 1
	if r.Method == "GET" {
		io.WriteString(w, "Echo server\n")
		return
	} else {
		r.ParseForm()
	}
	r.ParseForm()
	for k, v := range r.Form {
		io.WriteString(w, "\t"+k+"="+strings.Join(v, "")+"\n")
	}
	fmt.Print(counting, "\r")
}


func main() {
	http.HandleFunc("/", HandlePost)
	err := http.ListenAndServe("127.0.0.1:8080", nil)
	if err != nil {
		fmt.Println("ListenAndServe: ", err)
	}
}
