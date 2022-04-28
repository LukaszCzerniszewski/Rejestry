// Module to create a smart contract for attribute authentication.
package main

import (
	"log"

	Example "WAT/Example/smart-contract"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// Function to initialize smart contracts
func main() {
	ExampleSmartContract, err := contractapi.NewChaincode(&Example.SmartContract{})
	if err != nil {
		log.Panicf("Error creating Example chaincode: %v", err)
	}

	if err := ExampleSmartContract.Start(); err != nil {
		log.Panicf("Error starting Example chaincode: %v", err)
	}
}
