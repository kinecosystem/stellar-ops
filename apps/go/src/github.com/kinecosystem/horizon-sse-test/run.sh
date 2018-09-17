#!/usr/bin/env bash

go run main.go \
    -funder '' \
    -amount '10' \
    -horizon 'http://my.horizon.com' \
    -passphrase 'private testnet' \
    -ops 90 \
    -accounts 500
