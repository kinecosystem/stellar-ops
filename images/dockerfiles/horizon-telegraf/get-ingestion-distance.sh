#!/bin/sh
result=$(curl localhost)
core=$(echo $result|jq '.core_latest_ledger')
horizon=$(echo $result|jq '.history_latest_ledger')
echo 'ingestion_distance distance='$(($core-$horizon))