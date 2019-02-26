#!/bin/sh
result=$(curl stellar-core:11626/info)
agree=$(echo $result|jq '.info.quorum[].agree')
disagree=$(echo $result|jq '.info.quorum[].disagree')
echo 'LedgerStats agree='$agree',disagree='$disagree
