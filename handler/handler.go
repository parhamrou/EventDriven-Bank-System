package handler

import (
	   "fmt"
	   "github.com/parhamrou/EventDriven-Bank-System/model"
	db "github.com/parhamrou/EventDriven-Bank-System/database"
)

func Register() {
	var account model.Account
	fmt.Print("Username: ")
	fmt.Scan(&account.Username)
	fmt.Print("Password: ")
	fmt.Scan(&account.Password)
	fmt.Print("First name: ")
	fmt.Scan(&account.First_name)
	fmt.Print("Last name: ")
	fmt.Scan(&account.Last_name)
	fmt.Print("National ID: ")
	fmt.Scan(&account.National_id)
	fmt.Print("Date of birth: ")
	fmt.Scan(&account.Date_of_birth)
	fmt.Print("Type(employee, client): ")
	fmt.Scan(&account.Account_type)
	fmt.Print("Interest rate: ")
	fmt.Scan(&account.Interest_rate)
	db.Register(&account)
}

func Login() {
	var username, password string
	fmt.Print("Username: ")
	fmt.Scan(&username)
	fmt.Print("Password: ")
	fmt.Scan(&password)
	db.Login(username, password)
}

func Deposit() {
	var amount float32
	fmt.Print("Enter the amount of money: ")
	fmt.Scan(&amount)
	db.Deposit(amount)
}

func Withdraw() {
	var amount float32
	fmt.Print("Enter the amount of money: ")
	fmt.Scan(&amount)
	db.Withdraw(amount)
}

func Transfer() {
	var amount float32
	var accountNumber string
	fmt.Print("Enter the destination account number: ")
	fmt.Scan(&accountNumber)
	fmt.Print("Enter the amount of money: ")
	fmt.Scan(&amount)
	db.Transfer(accountNumber, amount)
}

func Interest_payment() {
	db.Interest_payment()
}

func Update_balances() {
	db.Update_balances()
}

func Check_balance() {
	db.Check_balance()
}