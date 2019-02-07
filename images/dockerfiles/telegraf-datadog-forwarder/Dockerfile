FROM telegraf:1.9.3-alpine
RUN apk add --no-cache gettext
COPY ./telegraf.conf.tmpl /etc/telegraf
EXPOSE 8086
CMD envsubst '${DATADOG_API_KEY} ${AWS_BI_ACCOUNT_ACCESS_KEY} ${AWS_BI_ACCOUNT_SECRET_KEY}' < /etc/telegraf/telegraf.conf.tmpl > /etc/telegraf/telegraf.conf && exec telegraf
