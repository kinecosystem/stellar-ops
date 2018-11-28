# Telegraf metric forwarder
This is a docker image that contains a telegraf client which receives input in influxdb format on port 8086 and transmits it to datadog and a local graphite (port 2003).

## Usage
In docker-compose, add the following service wherever you want your stats monitord.

services:
  telegraf-datadog-forwarder:
    image: kinecosystem/telegraf-datadog-forwarder:v1
    restart: on-failure
    environment:
      DATADOG_API_KEY: <the api key>
    logging:
      driver: json-file
      options:
        max-size: 100m
        max-file: "3"

## TODO
 
