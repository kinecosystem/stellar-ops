#!/bin/bash
# count how many nodes in the quorum agree and disagree on the last ledger

set -e

# argument parsing
ADDRESS='localhost:11626'

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -a|--address)
            ADDRESS="$2"
            shift # past argument
            shift # past value
            ;;
        *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

result=$(curl $ADDRESS/info)
printf 'info_quorum agree=%d,disagree=%d' \
    $(echo $result | jq -r '.info.quorum[].agree') \
    $(echo $result | jq -r '.info.quorum[].disagree')
