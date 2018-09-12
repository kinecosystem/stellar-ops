package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"math/rand"
	"net/http"
	"net/url"
	"strconv"
	"sync"
	"time"

	"github.com/hashicorp/go-retryablehttp"
	b "github.com/kinecosystem/go/build"
	"github.com/kinecosystem/go/keypair"
	sse "github.com/r3labs/sse"
)

var (
	seed       = flag.String("funder", "", "funder seed")
	amount     = flag.String("amount", "", "initial fund amount")
	horizon    = flag.String("horizon", "", "horizon url")
	passphrase = flag.String("passphrase", "", "network passhprase")
	ops        = flag.Uint("ops", "", "maximum operations per transaction")
	accounts   = flag.Uint("accounts", "", "accounts to create and use in test")

	accounts     = make(map[string]string, 0)
	addresses    = make([]string, 0)
	sse_channels = make(map[string]chan interface{}, 0)
)

func main() {
	flag.Parse()

	generateAccounts(*accounts)
	submitCreateAccounts()
	//checkSSEWithAdhocConnctions()
	checkSSEWithConstantConnections()
	fmt.Println("Done!")
}

func checkSSEWithAdhocConnections() {
	wg := new(sync.WaitGroup)
	wg.Add(299)
	for i := 0; i < 300; i++ {
		go func(sender int) {
			defer wg.Done()
			checkSSEOnPayment(i)
		}(i)
		time.Sleep(4 * time.Millisecond)
	}
	wg.Wait()
}

func checkSSEWithConstantConnections() {
	// create connections to all addresses
	for i := 0; i < len(addresses); i++ {
		channel := make(chan interface{})
		sse_channels[addresses[i]] = channel
		go func(address string, channel chan interface{}) {
			watchAccount(address, channel)
		}(addresses[i], channel)
		time.Sleep(4 * time.Millisecond)
	}

	runTestBulk(100)
	time.Sleep(20 * time.Second)
	runTestBulk(200)
	time.Sleep(20 * time.Second)
	runTestBulk(300)

}

func runTestBulk(count int) {
	wg := new(sync.WaitGroup)
	wg.Add(count)
	for i := 0; i < count; i++ {
		go func(sender int) {
			defer wg.Done()
			checkSSEOnPaymentConstant(i)
		}(i)
		time.Sleep(4 * time.Millisecond)
	}
	wg.Wait()
	fmt.Println("Finished bulk successfully")
}

func listenToHash(hash string, channel chan interface{}, wg *sync.WaitGroup) {
	defer wg.Done()
	select {
	case msg := <-channel:
		if msg == hash {
			fmt.Println("Matched ", hash)
			return
		}
	case <-time.After(30 * time.Second):
		fmt.Println("ERROR: missing event for hash: ", hash)
		return
	}
}

func checkSSEOnPaymentConstant(sender int) {
	rand.Seed(time.Now().UnixNano())
	receiver := rand.Intn(len(addresses))
	if sender == receiver {
		receiver = rand.Intn(len(addresses))
	}

	xdr, hash := createPayment(addresses[sender], addresses[receiver], 1)
	var wg sync.WaitGroup
	wg.Add(2)
	go listenToHash(hash, sse_channels[addresses[sender]], &wg)
	go listenToHash(hash, sse_channels[addresses[receiver]], &wg)
	sendPayment(xdr)
	wg.Wait()

}

func checkSSEOnPayment(sender int) {
	rand.Seed(time.Now().UnixNano())
	receiver := rand.Intn(len(addresses))
	if sender == receiver {
		receiver = rand.Intn(len(addresses))
	}

	xdr, hash := createPayment(addresses[sender], addresses[receiver], 1)
	wg := new(sync.WaitGroup)
	wg.Add(2)
	go func(senderAddress string, wg *sync.WaitGroup, hash string) {
		defer wg.Done()
		watchAccountForTrasnaction(senderAddress, hash, 25)
	}(addresses[sender], wg, hash)
	//	time.Sleep(10 * time.Millisecond)
	go func(receiverAddress string, wg *sync.WaitGroup, hash string) {
		defer wg.Done()
		watchAccountForTrasnaction(receiverAddress, hash, 25)
	}(addresses[receiver], wg, hash)
	sendPayment(xdr)
	wg.Wait()
}

func generateAccounts(num int) {
	for i := 0; i < num; i++ {
		kp, err := keypair.Random()
		if err != nil {
			panic(err)
		}
		accounts[kp.Address()] = kp.Seed()
		addresses = append(addresses, kp.Address())
	}
}

func getSequence(address string) uint64 {
	url := fmt.Sprintf("http://%s/accounts/%s", horizon, address)
	resp, err := retryablehttp.Get(url)
	if err != nil {
		panic(err)
	}
	resp.Close = true
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		panic(err)
	}
	var data map[string]interface{}
	err = json.Unmarshal([]byte(body), &data)
	if err != nil {
		panic(err)
	}
	val, _ := strconv.ParseUint(data["sequence"].(string), 10, 64)

	return val
}

func min(x int, y int) int {
	if x > y {
		return y
	} else {
		return x
	}
}

func submitCreateAccounts(funderAddr string) {
	for i := 0; i < len(addresses); {
		seq := getSequence(funderAddr) + 1

		args := []b.TransactionMutator{
			b.Network{passphrase},
			b.SourceAccount{funderAddr},
			b.Sequence{seq}}

		remaining := len(addresses) - i

		for j := 0; j < min(remaining, ops); j, i = j+1, i+1 {
			op := b.CreateAccount(b.Destination{addresses[i]}, b.NativeAmount{amount})
			args = append(args, op)
		}
		tx, err := b.Transaction(args...)
		if err != nil {
			panic(err)
		}

		txe, err := tx.Sign(seed)
		if err != nil {
			panic(err)
		}

		txeB64, err := txe.Base64()
		if err != nil {
			panic(err)
		}

		tx_url := fmt.Sprintf("http://%s/transactions", horizon)
		form := url.Values{"tx": []string{txeB64}}
		resp, err := http.PostForm(tx_url, form)
		resp.Close = true
		defer resp.Body.Close()
		if err != nil {
			fmt.Println("errorination happened getting the response", err)
		}
		body, err := ioutil.ReadAll(resp.Body)
		var data map[string]interface{}
		err = json.Unmarshal([]byte(body), &data)
		if err != nil {
			panic(err)
		}
		fmt.Println("Submitted addresses ", i)
	}

}

func sendPayment(xdr string) {
	tx_url := fmt.Sprintf("http://%s/transactions", horizon)
	form := url.Values{"tx": []string{xdr}}
	resp, err := retryablehttp.PostForm(tx_url, form)
	if err != nil {
		fmt.Println("errorination happened getting the response", err)
	} else {
		fmt.Println("Submitted ", xdr)
	}
	resp.Close = true
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	var data map[string]interface{}
	err = json.Unmarshal([]byte(body), &data)
	if err != nil {
		panic(err)
	}

}

func createPayment(sender string, receiver string, amount int) (xdr string, hash string) {
	seed := accounts[sender]
	seq := getSequence(sender) + 1
	//fmt.Println(seq)
	tx, err := b.Transaction(b.SourceAccount{sender}, b.Sequence{seq}, b.Network{passphrase},
		b.Payment(
			b.Destination{receiver},
			b.NativeAmount{strconv.Itoa(amount)},
		),
	)

	if err != nil {
		fmt.Println(err)
		return
	}

	txe, err := tx.Sign(seed)
	if err != nil {
		fmt.Println(err)
		return
	}

	txeB64, err := txe.Base64()

	if err != nil {
		fmt.Println(err)
		return
	}

	hash, err = tx.HashHex()
	fmt.Println("send from ", sender, " to ", receiver, ": ", hash)

	return txeB64, hash
}

func watchAccount(account string, watch_channel chan interface{}) {
	fmt.Println("Watching ", account)
	client := sse.NewClient(fmt.Sprintf("http://%s/accounts/%s/transactions?cursor=now", horizon, account))

	events := make(chan *sse.Event)

	client.SubscribeChan("messages", events)
	for {
		select {
		case msg := <-events:
			var raw map[string]interface{}
			err := json.Unmarshal(msg.Data, &raw)
			if err == nil {
				if raw["hash"] != nil {
					watch_channel <- raw["hash"]
				}
			}
		}
	}
}

func watchAccountForTrasnaction(account string, hash string, timeout int) {
	fmt.Println("Watching ", account, " : ", hash)
	client := sse.NewClient(fmt.Sprintf("http://%s/accounts/%s/transactions?cursor=now", horizon, account))

	events := make(chan *sse.Event)

	client.SubscribeChan("messages", events)
	for {
		select {
		case msg := <-events:
			var raw map[string]interface{}
			err := json.Unmarshal(msg.Data, &raw)
			if err == nil {
				if raw["hash"] == hash {
					fmt.Println("Match ", hash)
					return
				} else if raw["hash"] != nil {
					fmt.Println("Listening to ", account, ", hash: ", hash, " got ", raw["hash"])
				}
			}
		case <-time.After(time.Duration(timeout) * time.Second):
			fmt.Println("ERROR: missing event for ", account, ", hash: ", hash)
			return
		}
	}
}
