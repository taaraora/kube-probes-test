package main

import (
	"github.com/sirupsen/logrus"
	"net/http"
	"time"
)

func main() {
	logger := logrus.New()

	failureTime := time.Now().Add(time.Second * 20)

	livenessHandler := http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		w.WriteHeader(200)
		logger.Warnf("livenessProbe Handler was hit at %s", time.Now())
	})

	readinessHandler := http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		if failureTime.After(time.Now()) {
			w.WriteHeader(200)
			logger.Warnf("OK, readinessProbe Handler was hit at %s", time.Now())
			return
		}
		w.WriteHeader(500)
		logger.Warnf("FAILED readinessProbe Handler was hit at %s", time.Now())
	})

	mux := http.NewServeMux()
	mux.Handle("/liveness", livenessHandler)
	mux.Handle("/readiness", readinessHandler)
	srv := &http.Server{
		Handler:      mux,
		Addr:         ":4390",
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}
	logger.Info("Server is starting")

	go func() {
		logger.Fatal(srv.ListenAndServe())
	}()
	select {}
}
