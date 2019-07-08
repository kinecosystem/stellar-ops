#!/bin/bash
# process telegraf configuration template and start telegraf
envsubst '$NODE_NAME $NETWORK_NAME' < /etc/telegraf/telegraf.conf.tmpl > /etc/telegraf/telegraf.conf
exec telegraf
