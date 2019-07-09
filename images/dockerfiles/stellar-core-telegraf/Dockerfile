FROM telegraf:1.11

EXPOSE 8086

# input exec plugin dependencies
RUN apt-get update;apt-get install jq postgresql gettext ntp -y

COPY ./entrypoint.sh /

# custom telegraf input.exec plugins
COPY ./input-exec/*.sh /usr/bin/
RUN mkdir -p /opt/telegraf
COPY ./input-exec/core-connectivity-targets.txt /opt/telegraf

# telegraf configuration template
COPY ./telegraf.conf.tmpl /etc/telegraf/telegraf.conf.tmpl

ENTRYPOINT []
CMD /entrypoint.sh
