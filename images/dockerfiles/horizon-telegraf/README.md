# Horizon Telegraf

This is a docker image for a telegraf client that receives statsd stats from horizon's nginx and forwards them
in influx-db format to another location

## Usage
In docker-compose, add the following service next to the horizon's nginx one.

services:
  horizon-telegraf:
    image: kinecosystem/horizon-telegraf:latest
    restart: on-failure
    logging:
      driver: json-file
      options:
        max-size: 100m
        max-file: "3"

## TODO
 
