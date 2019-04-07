FROM telegraf:1.9.4-alpine
RUN apk add --no-cache curl gettext jq
COPY ./telegraf.conf.tmpl /etc/telegraf/telegraf.conf.tmpl
COPY ./get-core-synced-status.sh /tmp/
COPY ./get-core-state.sh /tmp/get_core_state.sh
COPY ./get-core-startedOn.sh /tmp/get_core_startedOn.sh
COPY ./get-ledger-stats.sh /tmp/get_ledger_stats.sh
COPY ./core-connectivity-check.sh /tmp/core_connectivity_check.sh
COPY ./core-connectivity-targets.txt /tmp/core_connectivity_targets.txt
EXPOSE 8086
CMD envsubst '$NODE_NAME $NETWORK_NAME' < /etc/telegraf/telegraf.conf.tmpl > /etc/telegraf/telegraf.conf && exec telegraf 
