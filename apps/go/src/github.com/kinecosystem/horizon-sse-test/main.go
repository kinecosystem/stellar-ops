package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"sync"
	"time"

	b "github.com/kinecosystem/go/build"
	"github.com/kinecosystem/go/clients/horizon"
	"github.com/kinecosystem/go/keypair"
	"github.com/r3labs/sse"
)

const ClientTimeout = 10 * time.Second

var (
	funderFlag     = flag.String("funder", "", "funder seed")
	amountFlag     = flag.String("amount", "", "initial fund amount")
	horizonFlag    = flag.String("horizon", "", "horizon url")
	passphraseFlag = flag.String("passphrase", "", "network passhprase")
	opsFlag        = flag.Int("ops", 1, "maximum operations per transaction")
	accountsFlag   = flag.Int("accounts", 1, "accounts to create and use in test")
)

func main() {
	flag.Parse()

	accounts, addresses := generateAccounts(*accountsFlag)

	client := horizon.Client{
		URL:  *horizonFlag,
		HTTP: &http.Client{Timeout: ClientTimeout},
	}

	submitCreateAccounts(&client, accounts, addresses, *funderFlag, *amountFlag, *opsFlag)

	// checkSSEWithAdhocConnections()
	checkSSEWithConstantConnections(&client, *passphraseFlag, addresses)

	log.Println("Done!")
}

func generateAccounts(num int) (map[string]string, []string) {
	accounts := make(map[string]string, 0)
	addresses := make([]string, 0)

	for i := 0; i < num; i++ {
		kp, err := keypair.Random()
		if err != nil {
			log.Panicln(err)
		}

		accounts[kp.Address()] = kp.Seed()
		addresses = append(addresses, kp.Seed())
	}

	return accounts, addresses
}

func submitCreateAccounts(client *horizon.Client, accounts map[string]string, addresses []string, funderSeed, amount string, maxOps int) {
	funder := keypair.MustParse(funderSeed).(*keypair.Full)

	for i := 0; i < len(addresses); {
		ops := append(
			[]b.TransactionMutator{},

			b.Network{Passphrase: *passphraseFlag},
			b.SourceAccount{AddressOrSeed: funder.Address()},
			b.AutoSequence{SequenceProvider: client},
		)

		remaining := len(addresses) - i

		for j := 0; j < min(remaining, maxOps); j, i = j+1, i+1 {
			ops = append(
				ops,
				b.CreateAccount(
					b.Destination{AddressOrSeed: addresses[i]},
					b.NativeAmount{Amount: amount},
				))
		}

		txBuilder, err := b.Transaction(ops...)
		if err != nil {
			log.Panicln(err)
		}

		txEnv, err := txBuilder.Sign(funder.Seed())
		if err != nil {
			log.Panicln(err)
		}

		txEnvB64, err := txEnv.Base64()
		if err != nil {
			log.Panicln(err)
		}

		log.Printf("submitting create transaction for %d: %d accounts\n", i, len(ops)-3)

	Retry:
		for j := 0; j < 5; j++ {
			_, err := client.SubmitTransaction(txEnvB64)
			if err == nil {
				break Retry
			}

			logTxErrorResultCodes(err)
			time.Sleep(1 * time.Second)
		}

		log.Println("success", i)
	}
}

func checkSSEWithConstantConnections(client *horizon.Client, passphrase string, addresses []string) {
	sseWatchChans := make(map[string]chan interface{}, len(addresses))

	// create connections to all addresses
	for i := 0; i < len(addresses); i++ {
		watchChan := make(chan interface{})
		sseWatchChans[addresses[i]] = watchChan

		kp := keypair.MustParse(addresses[i])
		go func(address string, channel chan interface{}) {
			watchAccount(client.URL, address, watchChan)
		}(kp.Address(), watchChan)

		time.Sleep(4 * time.Millisecond)
	}

	runTestBulk(client, passphrase, addresses, sseWatchChans, 100)
	time.Sleep(20 * time.Second)

	runTestBulk(client, passphrase, addresses, sseWatchChans, 200)
	time.Sleep(20 * time.Second)

	runTestBulk(client, passphrase, addresses, sseWatchChans, 300)
}

func watchAccount(horizon, account string, watchChan chan<- interface{}) {
	log.Printf("Watching %s\n", account)

	client := sse.NewClient(fmt.Sprintf("%s/accounts/%s/transactions?cursor=now", horizon, account))
	events := make(chan *sse.Event)
	client.SubscribeChan("messages", events)

	for msg := range events {
		var raw map[string]interface{}
		err := json.Unmarshal(msg.Data, &raw)
		if err == nil {
			if raw["hash"] != nil {
				watchChan <- raw["hash"]
			}
		}
	}
}

func runTestBulk(client *horizon.Client, passphrase string, addresses []string, sseWatchChans map[string]chan interface{}, count int) {
	var wg sync.WaitGroup
	wg.Add(count)
	for i := 0; i < count; i++ {
		go func(sender int) {
			defer wg.Done()
			checkSSEOnPaymentConstant(client, passphrase, addresses, sseWatchChans, i)
		}(i)

		time.Sleep(4 * time.Millisecond)
	}

	wg.Wait()

	log.Println("Finished bulk successfully")
}

func checkSSEOnPaymentConstant(client *horizon.Client, passphrase string, addresses []string, sseWatchChans map[string]chan interface{}, sender int) {
	rand.Seed(time.Now().UnixNano())
	receiver := rand.Intn(len(addresses))
	if sender == receiver {
		receiver = rand.Intn(len(addresses))
	}

	txEnvB64, hash := generatePayment(client, passphrase, addresses[sender], addresses[receiver], "1")

	var wg sync.WaitGroup
	wg.Add(2)
	go listenToHash(hash, sseWatchChans[addresses[sender]], &wg)
	go listenToHash(hash, sseWatchChans[addresses[receiver]], &wg)

Retry:
	for i := 0; i < 5; i++ {
		log.Printf("retry %d from %s to %s\n", i, addresses[sender], addresses[receiver])
		_, err := client.SubmitTransaction(txEnvB64)
		if err == nil {
			break Retry
		}

		logTxErrorResultCodes(err)
		if i == 4 {
			return
		}
	}

	wg.Wait()

}

func listenToHash(hash string, watchChan <-chan interface{}, wg *sync.WaitGroup) {
	defer wg.Done()
	select {
	case msg := <-watchChan:
		if msg == hash {
			fmt.Println("Matched ", hash)
			return
		}
	case <-time.After(30 * time.Second):
		fmt.Println("ERROR: missing event for hash: ", hash)
		return
	}
}

// func checkSSEWithAdhocConnections(client *horizon.Client, passphrase string, addresses []string) {
//	wg := new(sync.WaitGroup)
//	wg.Add(299)
//	for i := 0; i < 300; i++ {
//		go func(sender int) {
//			defer wg.Done()
//			checkSSEOnPayment(client, passphrase, addresses, i)
//		}(i)
//		time.Sleep(4 * time.Millisecond)
//	}
//	wg.Wait()
// }

//func checkSSEOnPayment(client *horizon.Client, passphrase string, addresses []string, sender int) {
//	rand.Seed(time.Now().UnixNano())
//	receiver := rand.Intn(len(addresses))
//	if sender == receiver {
//		receiver = rand.Intn(len(addresses))
//	}

//	txEnvB64, hash := generatePayment(client, passphrase, addresses[sender], addresses[receiver], "1")

//	var wg sync.WaitGroup
//	wg.Add(2)

//	go func(senderAddress string, wg *sync.WaitGroup, hash string) {
//		defer wg.Done()
//		watchAccountForTransaction(client.URL, senderAddress, hash, 25)
//	}(addresses[sender], &wg, hash)

//	//	time.Sleep(10 * time.Millisecond)

//	go func(receiverAddress string, wg *sync.WaitGroup, hash string) {
//		defer wg.Done()
//		watchAccountForTransaction(client.URL, receiverAddress, hash, 25)
//	}(addresses[receiver], &wg, hash)

//Retry:
//	for j := 0; j < 5; j++ {
//		_, err := client.SubmitTransaction(txEnvB64)
//		if err == nil {
//			break Retry
//		}

//		logTxErrorResultCodes(err)
//	}

//	wg.Wait()
//}

// func watchAccountForTransaction(horizon, account, hash string, timeout int) {
// 	fmt.Println("Watching ", account, " : ", hash)
// 	client := sse.NewClient(fmt.Sprintf("%s/accounts/%s/transactions?cursor=now", horizon, account))

// 	events := make(chan *sse.Event)

// 	client.SubscribeChan("messages", events)
// 	for {
// 		select {
// 		case msg := <-events:
// 			var raw map[string]interface{}
// 			err := json.Unmarshal(msg.Data, &raw)
// 			if err == nil {
// 				if raw["hash"] == hash {
// 					fmt.Println("Match ", hash)
// 					return
// 				} else if raw["hash"] != nil {
// 					fmt.Println("Listening to ", account, ", hash: ", hash, " got ", raw["hash"])
// 				}
// 			}
// 		case <-time.After(time.Duration(timeout) * time.Second):
// 			fmt.Println("ERROR: missing event for ", account, ", hash: ", hash)
// 			return
// 		}
// 	}
// }

func generatePayment(client *horizon.Client, passphrase, sender, receiver, amount string) (string, string) {
	tx, err := b.Transaction(
		b.SourceAccount{AddressOrSeed: sender},
		b.AutoSequence{SequenceProvider: client},
		b.Network{Passphrase: passphrase},

		b.Payment(
			b.Destination{AddressOrSeed: receiver},
			b.NativeAmount{Amount: amount},
		),
	)

	if err != nil {
		log.Println(err)
		return "", ""
	}

	txEnv, err := tx.Sign(sender)
	if err != nil {
		log.Println(err)
		return "", ""
	}

	txEnvB64, err := txEnv.Base64()
	if err != nil {
		log.Println(err)
		return "", ""
	}

	hash, err := tx.HashHex()
	if err != nil {
		log.Println(err)
		return "", ""
	}

	log.Printf("send from %s to %s: %s\b", sender, receiver, hash)

	return txEnvB64, hash
}

func logTxErrorResultCodes(err error) *horizon.TransactionResultCodes {
	log.Println(err)
	switch e := err.(type) {
	case *horizon.Error:
		code, err := e.ResultCodes()
		if err != nil {
			log.Println("failed to extract result codes from horizon response")
			return nil
		}
		log.Printf("code %s\n", code.TransactionCode)
		for i, opCode := range code.OperationCodes {
			log.Printf("opcode_index %s opcode %s\n", i, opCode)
		}

		return code
	default:
		log.Println("couldn't parse transaction error object")
	}
	return nil
}

func min(x int, y int) int {
	if x > y {
		return y
	} else {
		return x
	}
}
