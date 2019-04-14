#!/bin/bash
# count how many nodes in the quorum agree and disagree on the last ledger

set -e

result=$(curl -sS http://stellar-core:11626/info)

printf 'info_quorum agree=%d,disagree=%d\n' \
    $(echo $result | jq -r '.info.quorum[].agree') \
    $(echo $result | jq -r '.info.quorum[].disagree')
