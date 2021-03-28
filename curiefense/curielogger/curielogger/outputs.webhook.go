package main

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
)

//  _    ___   ___ ___ _____ _   ___ _  _
// | |  / _ \ / __/ __|_   _/_\ / __| || |
// | |_| (_) | (_ \__ \ | |/ _ \\__ \ __ |
// |____\___/ \___|___/ |_/_/ \_\___/_||_|
// WEBHOOK

type WebhookConfig struct {
	Enabled bool   `mapstructure:"enabled"`
	Url     string `mapstructure:"url"`
}

type webhookLogger struct {
	logger
	config WebhookConfig
}

func (l *webhookLogger) Configure(channel_capacity int) error {
	l.name = "Webhook"
	ch := make(chan LogEntry, channel_capacity)
	l.channel = ch
	l.do_insert = l.InsertEntry

	return nil
}

func (l *webhookLogger) InsertEntry(e LogEntry) bool {
	log.Printf("[DEBUG] Webhook insertion!")
	e.cfLog.Tags = append(e.cfLog.Tags, "curieaccesslog")
	j, err := json.Marshal(e.cfLog)
	if err == nil {
		_, err := http.Post(l.config.Url, "application/json", bytes.NewReader(j))
		if err != nil {
			log.Printf("ERROR: could not POST log entry: %v", err)
			return false
		}
	} else {
		log.Printf("[ERROR] Could not convert protobuf entry into json for ES insertion.")
		return false
	}
	return true
}
