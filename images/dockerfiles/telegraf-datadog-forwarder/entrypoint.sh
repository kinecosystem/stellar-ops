#!/bin/bash
# process telegraf configuration template and start telegraf

set -e

envsubst '${DATADOG_API_KEY} ${AWS_BI_ACCOUNT_ACCESS_KEY} ${AWS_BI_ACCOUNT_SECRET_KEY}' < /etc/telegraf/telegraf.conf.tmpl > /etc/telegraf/telegraf.conf
exec telegraf
