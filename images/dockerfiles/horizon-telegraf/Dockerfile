FROM telegraf:1.9.4-alpine
RUN apk add --no-cache curl gettext jq
RUN mkdir -p /opt/telegraf/scripts
COPY ./telegraf.conf.tmpl /etc/telegraf/telegraf.conf.tmpl
COPY ./check-latency.sh.tmpl /opt/telegraf/scripts/check_latency.sh.tmpl
COPY ./get-ingestion-distance.sh /opt/telegraf/scripts/get_ingestion_distance.sh
EXPOSE 8086
CMD envsubst '$REGION_NAME $NODE_NAME $NETWORK_NAME' < /etc/telegraf/telegraf.conf.tmpl > /etc/telegraf/telegraf.conf && envsubst '$TARGET_URL' < /opt/telegraf/scripts/check_latency.sh.tmpl > /opt/telegraf/scripts/check_latency.sh && chmod +x /opt/telegraf/scripts/check_latency.sh && exec telegraf
