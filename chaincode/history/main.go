package main

import (
	"encoding/json"
	"fmt"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"strings"
)

type Car struct {
	Model  string `json:"model"`
	Vin    string `json:"vin"`
	Owner  string `json:"owner"`
	Status string `json:"status"`
}

type SmartContract struct {
	contractapi.Contract
}

func (s *SmartContract) query(ctx contractapi.TransactionContextInterface, vin string) (*Car, error) {
	b, err := ctx.GetStub().GetState(vin)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state. %s", err.Error())
	}
	if b == nil {
		return nil, fmt.Errorf("%s does not exist", vin)
	}
	car := new(Car)
	_ = json.Unmarshal(b, car)

	return car, nil
}

func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	cars := []Car{
		{Model: "Toyota Camry", Owner: "Illya", Vin: "JT2BF22K6Y0283641", Status: "active"},
		{Model: "Acura", Owner: "Andre", Vin: "JH4KA8260RC000063", Status: "active"},
		{Model: "Chevrolet Impala", Owner: "Eugene", Vin: "2G1WF52K959355243", Status: "active"},
		{Model: "Ford F 150", Owner: "Ivan", Vin: "1FTPW125X5FA69245", Status: "active"},
	}

	for _, car := range cars {
		b, _ := json.Marshal(car)
		err := ctx.GetStub().PutState(car.Vin, b)

		if err != nil {
			return fmt.Errorf("failed to put to world state. %s", err.Error())
		}
	}

	return nil
}

func (s *SmartContract) NewCar(ctx contractapi.TransactionContextInterface, vin, model string) error {
	mspid, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get mspid: %s", err.Error())
	}
	if res := strings.Compare(mspid, "factory"); res != 0 {
		return fmt.Errorf("available only for factory")
	}
	car := &Car{
		Model:  model,
		Vin:    vin,
		Owner:  "-",
		Status: "active",
	}

	if c, _ := s.query(ctx, vin); c == nil {
		b, _ := json.Marshal(car)
		return ctx.GetStub().PutState(vin, b)
	}
	return fmt.Errorf("%s exists", vin)
}

func (s *SmartContract) SetInactive(ctx contractapi.TransactionContextInterface, vin string) error {
	mspid, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get mspid: %s", err.Error())
	}
	if res := strings.Compare(mspid, "insurance"); res != 0 {
		return fmt.Errorf("available only for insurance")
	}
	if c, _ := s.query(ctx, vin); c != nil {
		c.Status = "inactive"
		b, _ := json.Marshal(c)
		err = ctx.GetStub().PutState(vin, b)
		if err != nil {
			return fmt.Errorf("failed to update car history")
		}
		return nil
	}
	return fmt.Errorf("%s does not exist", vin)
}

func (s *SmartContract) ChangeOwner(ctx contractapi.TransactionContextInterface, vin, owner string) error {
	mspid, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get mspid: %s", err.Error())
	}
	if res := strings.Compare(mspid, "police"); res != 0 {
		return fmt.Errorf("available only for police")
	}
	car, err := s.query(ctx, vin)
	if err != nil {
		return err
	}
	fmt.Println(car)
	if car.Status == "active" {
		car.Owner = owner
	} else {
		return fmt.Errorf("car status is inactive %s", vin)
	}
	b, _ := json.Marshal(car)

	return ctx.GetStub().PutState(vin, b)
}

func main() {
	chaincode, err := contractapi.NewChaincode(new(SmartContract))
	if err != nil {
		fmt.Printf("Error create smart contract chaincode: %s", err.Error())
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting smart contract chaincode: %s", err.Error())
	}
}
