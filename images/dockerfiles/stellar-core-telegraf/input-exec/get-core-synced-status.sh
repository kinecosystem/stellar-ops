#!/bin/bash
# return 1 if core is in synced state, 0 otherwise

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

# BOOTING=0
# JOIN_SCP=1
# LEDGER_SYNC=2
# CATCHING_UP=3
# SYNCED=4,  <-- we care about this
# STOPPING=5
case "$(curl -sS $ADDRESS/metrics | jq -r '.metrics."app.state.current".count')" in
    "4") state='1' ;;
    *) state='0' ;;
esac

printf 'synced synced=%d\n' $state
