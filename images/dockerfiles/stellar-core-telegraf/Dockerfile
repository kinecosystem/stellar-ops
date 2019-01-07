FROM telegraf:1.8.3-alpine
RUN apk add --no-cache curl gettext jq
COPY ./telegraf.conf.tmpl /etc/telegraf/telegraf.conf.tmpl
COPY ./get-core-state.sh /tmp/get_core_state.sh
COPY ./get-core-startedOn.sh /tmp/get_core_startedOn.sh
EXPOSE 8086
CMD envsubst '$NODE_NAME $NETWORK_NAME' < /etc/telegraf/telegraf.conf.tmpl > /etc/telegraf/telegraf.conf && exec telegraf 
