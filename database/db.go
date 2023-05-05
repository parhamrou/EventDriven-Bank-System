package database

import (
	"database/sql"
	_ "github.com/lib/pq"
	"fmt"
	"log"
	"github.com/parhamrou/EventDriven-Bank-System/model"
)

var db *sql.DB

const (
	host     = "localhost"
	port     = 5432
	user     = "parhamrou"
	password = "parham1381"
	dbname   = "bank_system"
)

func Connect() error {
	var err error
	dsn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", host, port, user, password, dbname)
	db, err = sql.Open("postgres", dsn)
	if err != nil {
		return err
	}
	err = db.Ping()
	return err
}

func Register(account *model.Account) {
	if err := db.Ping(); err != nil {
		log.Fatal(err)
	}
	query := `CALL register($1, $2, $3, $4, $5, $6, $7, $8)`
	if _,err := db.Exec(query, account.Username, account.Password, account.First_name, account.Last_name,
		account.National_id, account.Date_of_birth, account.Account_type, account.Interest_rate); err != nil {
			fmt.Println(err)
			return
		}
	fmt.Println("You registered successfully!")
}

func Login(username string, password string) {
	if err := db.Ping(); err != nil {
		log.Fatal(err)
	}
	query := `CALL login($1, $2)`
	if _, err := db.Exec(query, username, password); err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println("You logged in successfully!")
}

func Deposit(amount float32) {
	if err := db.Ping(); err != nil {
		log.Fatal(err)
	}
	query := `CALL deposit($1)`
	if _, err := db.Exec(query, amount); err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println("Done sunccessfully!")
}

func Withdraw(amount float32) {
	if err := db.Ping(); err != nil {
		log.Fatal(err)
	}
	query := `CALL withdraw($1)`
	if _, err := db.Exec(query, amount); err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println("Done successfully!")
}

func Transfer(dest_accnum string, amount float32) {
	if err := db.Ping(); err != nil {
		log.Fatal(err)
	}
	query := `CALL transfer($1, $2)`
	if _, err := db.Exec(query, dest_accnum, amount); err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println("Transfer has been done successfully!")
}

func Interest_payment() {
	if err := db.Ping(); err != nil {
		log.Fatal(err)
	}
	query := `CALL interest_payment()`
	if _, err := db.Exec(query); err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println("Done successfully!")
}

func Update_balances() {
	if err := db.Ping(); err != nil {
		log.Fatal(err)
	}
	query := `CALL update_balances()`
	if _, err := db.Exec(query); err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println("Balances are updated now!")
}

func Check_balance() {
	if err := db.Ping(); err != nil {
		log.Fatal(err)
	}
	var balance float32
	query := `CALL check_balance($1)`
	if  err := db.QueryRow(query, balance).Scan(&balance); err != nil {
		fmt.Println(err)
		return
	}
	fmt.Printf("You balance is %f$\n", balance)
}
