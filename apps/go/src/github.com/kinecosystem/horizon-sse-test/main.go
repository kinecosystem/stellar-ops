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

type Account struct {
	KP *keypair.Full

	// key:value is transaction hash : got pubsub message for that transaction
	Txs sync.Map
}

type Accounts map[string]*Account

const ClientTimeout = 30 * time.Second

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

	accounts := generateAccounts(*accountsFlag)

	client := horizon.Client{
		URL:  *horizonFlag,
		HTTP: &http.Client{Timeout: ClientTimeout},
	}

	submitCreateAccounts(&client, accounts, *funderFlag, *amountFlag, *opsFlag)

	checkSSEWithConstantConnections(&client, *passphraseFlag, accounts)

	log.Println("Done!")
}

func generateAccounts(num int) Accounts {
	accounts := make(Accounts, num)

	for i := 0; i < num; i++ {
		kp, err := keypair.Random()
		if err != nil {
			log.Panicln(err)
		}

		accounts[kp.Address()] = &Account{KP: kp}
	}

	return accounts
}

func submitCreateAccounts(client *horizon.Client, accounts Accounts, funderSeed, amount string, maxOps int) {
	funder := keypair.MustParse(funderSeed).(*keypair.Full)

	ops := append(
		[]b.TransactionMutator{},

		b.Network{Passphrase: *passphraseFlag},
		b.SourceAccount{AddressOrSeed: funder.Address()},
		b.AutoSequence{SequenceProvider: client},
	)
	i := 0
	for _, acc := range accounts {
		ops = append(
			ops,
			b.CreateAccount(
				b.Destination{AddressOrSeed: acc.KP.Address()},
				b.NativeAmount{Amount: amount},
			))

		if len(ops)-3 == maxOps || i == len(accounts)-1 {
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

			log.Printf("submitting create transaction %d accounts, total %d\n", len(ops)-3, i+1)

		Retry:
			for j := 0; j < 5; j++ {
				_, err := client.SubmitTransaction(txEnvB64)
				if err == nil {
					break Retry
				}

				logTxErrorResultCodes(err)
				time.Sleep(1 * time.Second)
			}

			log.Println("success")

			ops = append(
				[]b.TransactionMutator{},

				b.Network{Passphrase: *passphraseFlag},
				b.SourceAccount{AddressOrSeed: funder.Address()},
				b.AutoSequence{SequenceProvider: client},
			)
		}

		i++
	}
}

func checkSSEWithConstantConnections(client *horizon.Client, passphrase string, accounts Accounts) {
	events := make(map[string]chan interface{}, len(accounts))

	// create connections to all addresses
	for _, acc := range accounts {
		accEvents := make(chan interface{}, 500)
		events[acc.KP.Address()] = accEvents

		go func(acc *Account, channel chan interface{}) {
			watchAccount(client.URL, acc, accEvents)
		}(acc, accEvents)

		time.Sleep(4 * time.Millisecond)
	}

	// all txs should be confirmed in 1 block
	log.Println("-------------- BULK 1")
	success := runTestBulk(client, passphrase, accounts, events, 100)
	if !success {
		return
	}
	cleanTxs(accounts)
	time.Sleep(20 * time.Second)

	// all txs should be confirmed in 2 blocks
	log.Println("-------------- BULK 2")
	success = runTestBulk(client, passphrase, accounts, events, 200)
	if !success {
		return
	}
	cleanTxs(accounts)
	time.Sleep(20 * time.Second)

	// all txs should be confirmed in 3 blocks
	log.Println("-------------- BULK 3")
	success = runTestBulk(client, passphrase, accounts, events, 300)
	if !success {
		return
	}
	cleanTxs(accounts)
	time.Sleep(20 * time.Second)

	log.Println("-------------- BULK 4")
	runTestBulk(client, passphrase, accounts, events, 500)
}

func watchAccount(horizon string, sender *Account, accEvents chan<- interface{}) {
	log.Printf("Watching %s\n", sender.KP.Address())

	for {
		client := sse.NewClient(fmt.Sprintf("%s/accounts/%s/transactions?cursor=now", horizon, sender.KP.Address()))
		events := make(chan *sse.Event)
		client.SubscribeChan("messages", events)

		// loop will end once events closes, which happens when the sse connection is terminated by horizon
		for msg := range events {
			var raw map[string]interface{}
			err := json.Unmarshal(msg.Data, &raw)
			if err == nil {
				if raw["hash"] != nil { // TODO what happens if it's nil?
					log.Printf("sse published to account %s tx hash %s", sender.KP.Address(), raw["hash"])

					sender.Txs.Store(raw["hash"], true)
				} else {
					log.Println(raw)
				}
			}
		}
	}
}

func runTestBulk(client *horizon.Client, passphrase string, accounts Accounts, events map[string]chan interface{}, count int) bool {
	// Initialize tx envelopes for submission,
	// along with tx hash test map for verification at the end
	txs := make(map[string]string) // TxHash : TxEnvB64
	c := 0
	for _, sender := range accounts {

		// Generate transaction as well as its extract hash
		receiver, hash, txEnvB64 := generatePayment(client, passphrase, accounts, sender, "1")
		txs[hash] = txEnvB64

		// Initialize tx hash as "not yet published".
		log.Printf("Watching tx %d from %s to %s with tx hash %s\n", c+1, sender.KP.Address(), receiver.KP.Address(), hash)
		accounts[sender.KP.Address()].Txs.Store(hash, false)

		c++
		if c >= count {
			break
		}
	}

	var wg sync.WaitGroup
	wg.Add(count)
	c = 0
	for hash, txEnvB64 := range txs {
		go func(hash, txEnvB64 string) {
			defer wg.Done()
			submitTx(client, hash, txEnvB64)
		}(hash, txEnvB64)

		time.Sleep(50 * time.Millisecond)

		c++
		if c >= count {
			break
		}
	}

	wg.Wait()

	// sleep how many blocks is required for all transactions to be processed
	// e.g. 200 requires 2 blocks (because we set 100 txs / block)
	// we also wait an extra block just in case
	//
	// so in the above example we'll wait 3 blocks
	time.Sleep(time.Duration(((5*count)/100)+5) * time.Second)

	res := testAllTxsPublished(accounts)
	return res
}

func submitTx(client *horizon.Client, hash, txEnvB64 string) {
	for i := 0; i < 5; i++ {
		log.Printf("submit attempt %d for tx hash: %s\n", i+1, hash)
		_, err := client.SubmitTransaction(txEnvB64)
		if err == nil {
			log.Printf("submit success %d for tx hash: %s\n", i+1, hash)
			return
		}

		logTxErrorResultCodes(err)
		if i == 4 {
			log.Panicln(err)
		}
	}
}

func testAllTxsPublished(accounts Accounts) bool {
	res := true
	i := 0
	for _, acc := range accounts {
		acc.Txs.Range(func(hash, published interface{}) bool {
			if published.(bool) {
				log.Printf("tx hash: %d match %s\n", i+1, hash)
			} else {
				log.Printf("tx hash: %d MISSING: missing event hash: %s\n", i+1, hash)
				res = false
			}

			i++
			return true // continue iteration
		})
	}
	return res
}

func generatePayment(client *horizon.Client, passphrase string, accounts Accounts, sender *Account, amount string) (*Account, string, string) {
	// Filter sender from addresses
	// and randomly pick receiver address from remaining addresses
	var receivers []*Account
	for _, acc := range accounts {
		if acc.KP.Address() != sender.KP.Address() {
			receivers = append(receivers, acc)
		}
	}
	rand.Seed(time.Now().UnixNano())
	receiver := receivers[rand.Intn(len(receivers))]

	tx, err := b.Transaction(
		b.SourceAccount{AddressOrSeed: sender.KP.Address()},
		b.AutoSequence{SequenceProvider: client},
		b.Network{Passphrase: passphrase},

		b.Payment(
			b.Destination{AddressOrSeed: receiver.KP.Address()},
			b.NativeAmount{Amount: amount},
		),
	)

	if err != nil {
		log.Println(err)
		return nil, "", ""
	}

	txEnv, err := tx.Sign(sender.KP.Seed())
	if err != nil {
		log.Println(err)
		return nil, "", ""
	}

	txEnvB64, err := txEnv.Base64()
	if err != nil {
		log.Println(err)
		return nil, "", ""
	}

	hash, err := tx.HashHex()
	if err != nil {
		log.Println(err)
		return nil, "", ""
	}

	return receiver, hash, txEnvB64
}

func cleanTxs(accounts Accounts) {
	for _, acc := range accounts {
		acc.Txs.Range(func(hash, _ interface{}) bool {
			acc.Txs.Delete(hash.(string))
			return true // continue iteration
		})
	}
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
