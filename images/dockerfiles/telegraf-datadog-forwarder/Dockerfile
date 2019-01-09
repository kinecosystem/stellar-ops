FROM telegraf:1.8.3-alpine
RUN apk add --no-cache gettext
COPY ./telegraf.conf.tmpl /etc/telegraf
EXPOSE 8086
CMD envsubst '${DATADOG_API_KEY}' < /etc/telegraf/telegraf.conf.tmpl > /etc/telegraf/telegraf.conf && exec telegraf
