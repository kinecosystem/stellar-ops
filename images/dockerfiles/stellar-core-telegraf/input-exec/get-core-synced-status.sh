#!/bin/sh
set -e

case "$(curl -sS localhost:11626/metrics | jq -r '.metrics."app.state.current".count')" in
    "4") state='1' ;;  # 4 = Synced
    *) state='0' ;;
esac

printf 'state state=%d\n' $state
