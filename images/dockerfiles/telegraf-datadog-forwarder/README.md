# Telegraf metric forwarder
This is a docker image that contains a telegraf client which receives input on statsd or influx format
and transmits it to datadog.

## Usage
In docker-compose, add the following service wherever you want your stats monitord.

services:
  telegraf-datadog-forwarder:
    image: kinecosystem/telegraf-datadog-forwarder:latest
    restart: on-failure
    environment:
      DATADOG_API_KEY: <the api key>
    logging:
      driver: json-file
      options:
        max-size: 100m
        max-file: "3"

## TODO
 
