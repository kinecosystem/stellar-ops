#!/bin/bash
# return 1 if core is in synced state, 0 otherwise

set -e

# BOOTING=0
# JOIN_SCP=1
# LEDGER_SYNC=2
# CATCHING_UP=3
# SYNCED=4,  <-- we care about this
# STOPPING=5
case "$(curl -sS http://stellar-core:11626/metrics | jq -r '.metrics."app.state.current".count')" in
    "4") state='1' ;;
    *) state='0' ;;
esac

printf 'app_state_synced synced=%d\n' $state
