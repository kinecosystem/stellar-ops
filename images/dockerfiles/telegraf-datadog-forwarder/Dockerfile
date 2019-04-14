FROM telegraf:1.9.5-alpine

EXPOSE 8086

# envsubst requirement
RUN apk add -qU --no-cache gettext

COPY ./entrypoint.sh /
COPY ./telegraf.conf.tmpl /etc/telegraf

ENTRYPOINT []
CMD /entrypoint.sh
