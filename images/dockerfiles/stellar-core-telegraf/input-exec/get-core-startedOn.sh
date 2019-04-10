#!/bin/sh
result=$(curl stellar-core:11626/info|jq .'info.startedOn'| tr 'T' ' '|tr -d "\"Z")
result=$(date -d "$result" +"%s")
echo 'startedOn time='$result
