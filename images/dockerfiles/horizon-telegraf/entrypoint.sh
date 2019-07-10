#!/bin/bash
# process telegraf configuration template and start telegraf

service ntp start

set -e
if [ -z ${FORWARDER_URL+x} ]; then export FORWARDER_URL="http://metrics.kininfrastructure.com:8086"; fi
envsubst '$REGION_NAME $NODE_NAME $NETWORK_NAME $FORWARDER_URL' < /etc/telegraf/telegraf.conf.tmpl > /etc/telegraf/telegraf.conf

envsubst '$TARGET_URL' < /opt/telegraf/scripts/check-latency.sh.tmpl > /opt/telegraf/scripts/check-latency.sh
chmod +x /opt/telegraf/scripts/check-latency.sh

exec telegraf

