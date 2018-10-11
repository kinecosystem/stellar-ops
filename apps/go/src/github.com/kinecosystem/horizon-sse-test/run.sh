#!/usr/bin/env bash

ONE_DIR_UP=$(dirname $PWD)
TWO_DIR_UP=$(dirname $ONE_DIR_UP)
THREE_DIR_UP=$(dirname $TWO_DIR_UP)
FOUR_DIR_UP=$(dirname $THREE_DIR_UP)

GOPATH="$FOUR_DIR_UP:$GOPATH" go run main.go \
    -funder '' \
    -amount '10' \
    -horizon 'http://my.horizon.com' \
    -passphrase 'private testnet' \
    -ops 90 \
    -accounts 500
