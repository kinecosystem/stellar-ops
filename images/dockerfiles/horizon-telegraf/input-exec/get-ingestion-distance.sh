#!/bin/bash
# this script calculates and prints the difference between the latest ledger in core
# and the latest ingested ledger in horizon (history latest ledger)

set -e

result=$(curl -sS ${1:-localhost})

core=$(echo $result | jq -r '.core_latest_ledger')
horizon=$(echo $result | jq -r '.history_latest_ledger')

printf 'ingestion_distance distance=%d\n' $(( $core - $horizon ))
