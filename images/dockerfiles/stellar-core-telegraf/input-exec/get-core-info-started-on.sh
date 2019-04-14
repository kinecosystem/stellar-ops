#!/bin/bash
# get core started on date, in order to learn about crashes and restarts

set -e

result=$(curl -sS http://stellar-core:11626/info | jq .'info.startedOn' | tr 'T' ' ' | tr -d "\"Z")
result=$(date -d "$result" +"%s")

printf 'info_started_on time=%s\n' $result
