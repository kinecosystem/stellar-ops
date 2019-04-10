#!/bin/sh
set -e

# BOOTING=0
# JOIN_SCP=1
# LEDGER_SYNC=2
# CATCHING_UP=3
# SYNCED=4,
# STOPPING=5
printf 'state state=%d\n' "$(curl -sS localhost:11626/metrics | jq -r '.metrics."app.state.current".count')"

