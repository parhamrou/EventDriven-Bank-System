package cli

import (
	"fmt"
	"os"
	"os/exec"
	"github.com/parhamrou/EventDriven-Bank-System/handler"
)

func MainMenu() {
	fmt.Println("Welcome!")
	var choice int
	loop:
	for {
		ClearScreen()
		PrintOptions()
		fmt.Scan(&choice)
		switch choice {
		case 1:
			handler.Register()
		case 2:
			handler.Login()
		case 3:
			handler.Deposit()
		case 4:
			handler.Withdraw()
		case 5:
			handler.Transfer()
		case 6:
			handler.Interest_payment()
		case 7:
			handler.Update_balances()
		case 8:
			handler.Check_balance()
		case 9:
			break loop
		default:
			fmt.Println("Invalid input!")
		}
	}
}

func PrintOptions() {
	fmt.Println("1. Register")
	fmt.Println("2. Login")
	fmt.Println("3. Deposit")
	fmt.Println("4. Withdraw")
	fmt.Println("5. Transfer")
	fmt.Println("6. Interest Payment")
	fmt.Println("7. Update balances")
	fmt.Println("8. Check balance")
	fmt.Println("9. Exit")
	fmt.Print("> ")
}

func ClearScreen() {
	cmd := exec.Command("Clear") //Linux example, its tested
	cmd.Stdout = os.Stdout
	cmd.Run()
}