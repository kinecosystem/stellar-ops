#!/bin/bash
# get core started on date, in order to learn about crashes and restarts

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

result=$(curl -sS $ADDRESS/info | jq .'info.startedOn' | tr 'T' ' ' | tr -d "\"Z")
result=$(date -d "$result" +"%s")

printf 'startedOn time=%s' $result
