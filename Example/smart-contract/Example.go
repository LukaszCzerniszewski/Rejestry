package Example

import (
	"encoding/json"
	"fmt"
	"log"
	"strings"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing ...
type SmartContract struct {
	contractapi.Contract
}

type ParcelType struct {
	ID           string `json:"id"`
	Destination  string `json:"destination"`
	Product_List string `json:"product_list"`
	Consignor    string `json:"consignor"`
	Localization string `json:"localization"`
}

func (s *SmartContract) RegisterParcel(ctx contractapi.TransactionContextInterface, Destination string, Product_List string, Consignor string) string {
	log.Printf("============Parcel Registration============")
	if Destination == "" {
		log.Printf("Destination is empty")
		return fmt.Errorf("Destination is empty").Error()
	}
	if Product_List == "" {
		log.Printf("list of Product_List is empty")
		return fmt.Errorf("list of Product_List is empty").Error()
	}
	if Consignor == "" {
		log.Printf("Consignor is empty")
		return fmt.Errorf("Consignor is empty").Error()
	}
	var parcel ParcelType
	parcel.Consignor = Consignor
	parcel.Product_List = Product_List
	parcel.Destination = Destination
	parcel.Localization = "Initial localization"
	parcel.ID = ctx.GetStub().GetTxID()

	parcelJSON, err := ctx.GetStub().GetState(parcel.ID)
	if err != nil {
		log.Printf("failed to read from world state: %v", err)
		return fmt.Errorf("failed to read from world state: %v", err).Error()
	}
	if parcelJSON != nil {
		log.Printf("the parcel %s exist", parcel.ID)
		return fmt.Errorf("the parcel %s exist", parcel.ID).Error()
	}

	//Create JSON
	parcelJSON, err = json.Marshal(parcel)
	if err != nil {
		log.Printf("failed to create JSON: %v", err)
		return fmt.Errorf("failed to create JSON: %v", err).Error()
	}

	// Write parcel object to ledger
	err = ctx.GetStub().PutState(parcel.ID, parcelJSON)
	if err != nil {
		log.Printf("Error while adding new parcel to ledger: " + err.Error() + "")
		return fmt.Errorf("Error while adding new parcel to ledger: " + err.Error() + "").Error()
	}
	return parcel.ID
}

func (s *SmartContract) GetParcel(ctx contractapi.TransactionContextInterface, id string) (string, error) {
	log.Printf("============Get Parcel============")

	parcelJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		log.Printf("failed to read from world state: %v", err)
		return "", fmt.Errorf("failed to read from world state: %v", err)
	}
	if parcelJSON == nil {
		log.Printf("the user %s does not exist", id)
		return "", fmt.Errorf("the user %s does not exist", id)
	}
	// Return Parcel
	return string(parcelJSON), nil
}

func (s *SmartContract) SortingO1(ctx contractapi.TransactionContextInterface, ID string) string {
	log.Printf("============Parcel Sort O1============")
	if ID == "" {
		log.Printf("ID is empty")
		return fmt.Errorf("ID is empty").Error()
	}
	request_Org, _ := ctx.GetClientIdentity().GetMSPID()
	if !strings.EqualFold("Org1MSP", request_Org) {
		log.Printf("wrong organization: %v", request_Org)
		return fmt.Errorf("wrong organization: %v", request_Org).Error()
	}
	parcelJSON, err := ctx.GetStub().GetState(ID)
	if err != nil {
		log.Printf("failed to read from world state: %v", err)
		return fmt.Errorf("failed to read from world state: %v", err).Error()
	}
	if parcelJSON == nil {
		log.Printf("the parcel %s exist", ID)
		return fmt.Errorf("the parcel %s exist", ID).Error()
	}
	var parcel ParcelType
	err = json.Unmarshal(parcelJSON, &parcel)
	if err != nil {
		log.Printf("failed to unmarshall JSON parcel: %v", err)
		return fmt.Errorf("failed to unmarshall JSON parcel: %v", err).Error()
	}
	parcel.Localization = "Sorting facility ORG1"
	//Create JSON
	parcelJSON, err = json.Marshal(parcel)
	if err != nil {
		log.Printf("failed to create JSON: %v", err)
		return fmt.Errorf("failed to create JSON: %v", err).Error()
	}

	// Write parcel object to ledger
	err = ctx.GetStub().PutState(parcel.ID, parcelJSON)
	if err != nil {
		log.Printf("Error while adding new parcel to ledger: " + err.Error() + "")
		return fmt.Errorf("Error while adding new parcel to ledger: " + err.Error() + "").Error()
	}
	return parcel.ID
}
