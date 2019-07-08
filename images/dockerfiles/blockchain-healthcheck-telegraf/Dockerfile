FROM telegraf:1.9.5-alpine

EXPOSE 8086

# input exec plugin dependencies
RUN apk add -qU --no-cache curl gettext

COPY ./entrypoint.sh /

# custom telegraf input.exec plugins
RUN mkdir -p /opt/telegraf

# telegraf configuration template
COPY ./telegraf.conf.tmpl /etc/telegraf/telegraf.conf.tmpl

ENTRYPOINT []
CMD /entrypoint.sh
