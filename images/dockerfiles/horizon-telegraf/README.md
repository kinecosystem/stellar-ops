# Horizon telegraf

This is a docker image that collects various measurements from the horizon instance.
at the moment it collects:
1. the latency of /info requests from the horizon to its core

In addition, this telegraf also collects statsd metrics from the nginx

## Usage
In docker-compose, add the following service next to the horizon one.

services:
---
version: "3"
services:
  horizon-telegraf:
    environment:
      NODE_NAME: "<node-name-goes-here, like ecosystem2300>"
      NETWORK_NAME: "<network-name-goes-here, like ecosystem>"
      TARGET_URL: "http://<core-url-goes-here>:11626/info"
      REGION_NAME: "us-east-1" # region at which the infrastructure is located, for cloudwatch metrics
    image: kinecosystem/horizon-telegraf
    restart: always
    logging:
      driver: json-file
      options:
        max-size: 100m
        max-file: "3"

## TODO
 
