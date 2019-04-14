FROM telegraf:1.9.4-alpine

EXPOSE 8086

# input exec plugin dependencies
RUN apk add -qU --no-cache curl gettext jq

COPY ./entrypoint.sh /

RUN mkdir -p /opt/telegraf/scripts
COPY ./check-latency.sh.tmpl /opt/telegraf/scripts/check_latency.sh.tmpl
COPY ./get-ingestion-distance.sh /opt/telegraf/scripts/get_ingestion_distance.sh

COPY ./telegraf.conf.tmpl /etc/telegraf/telegraf.conf.tmpl

ENTRYPOINT []
CMD /entrypoint.sh
