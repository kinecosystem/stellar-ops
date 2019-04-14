FROM telegraf:1.9.4-alpine

EXPOSE 8086

# input exec plugin dependencies
RUN apk add -qU --no-cache curl gettext jq

COPY ./entrypoint.sh /

RUN mkdir -p /opt/telegraf/scripts
COPY ./input-exec/*.sh.tmpl /opt/telegraf/scripts/
COPY ./input-exec/*.sh /opt/telegraf/scripts/

COPY ./telegraf.conf.tmpl /etc/telegraf/telegraf.conf.tmpl

ENTRYPOINT []
CMD /entrypoint.sh
