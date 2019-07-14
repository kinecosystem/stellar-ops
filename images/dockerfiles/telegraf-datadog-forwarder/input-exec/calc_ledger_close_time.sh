#!/usr/bin/env bash

url="https://horizon-block-explorer.kininfrastructure.com/ledgers?limit=2&order=desc"
data=$(curl -s "$url")
ledger0=$(echo "$data" | jq -r "._embedded.records[0].closed_at")
ledger1=$(echo "$data" | jq -r "._embedded.records[1].closed_at")
diff=$(echo $(date --date="$ledger0" +%s) - $(date --date="$ledger1" +%s) | bc)
printf 'ledger_close_time stellar_network=prod seconds=%d\n' $diff
