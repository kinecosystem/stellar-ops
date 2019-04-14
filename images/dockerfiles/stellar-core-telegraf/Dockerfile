FROM telegraf:1.9.4-alpine

EXPOSE 8086

# input exec plugin dependencies
RUN apk add -qU --no-cache curl gettext jq

COPY ./entrypoint.sh /

# custom telegraf input.exec plugins
COPY ./input-exec/*.sh /usr/bin/
RUN mkdir -p /opt/telegraf
COPY ./input-exec/core-connectivity-targets.txt /opt/telegraf

# telegraf configuration template
COPY ./telegraf.conf.tmpl /etc/telegraf/telegraf.conf.tmpl

ENTRYPOINT []
CMD /entrypoint.sh
