package main

import (
	"log"

	"github.com/parhamrou/EventDriven-Bank-System/cli"
	db "github.com/parhamrou/EventDriven-Bank-System/database"
)

func main() {
	if err := db.Connect(); err != nil {
		log.Fatal(err)
	}
	cli.MainMenu()
}