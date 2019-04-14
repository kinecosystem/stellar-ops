#!/bin/bash
# process telegraf configuration template and start telegraf

set -e

envsubst '$REGION_NAME $NODE_NAME $NETWORK_NAME' < /etc/telegraf/telegraf.conf.tmpl > /etc/telegraf/telegraf.conf

envsubst '$TARGET_URL' < /opt/telegraf/scripts/check-latency.sh.tmpl > /opt/telegraf/scripts/check-latency.sh
chmod +x /opt/telegraf/scripts/check-latency.sh

exec telegraf

