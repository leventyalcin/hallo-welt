package main

import (
  "fmt"
  "log"
  "net/http"
)

func main() {
  http.HandleFunc("/", func(w http.ResponseWriter, req *http.Request) {
    fmt.Fprintln(w, "Hallo Welt")
  })
  log.Fatal(http.ListenAndServe(":8080", nil))
}
