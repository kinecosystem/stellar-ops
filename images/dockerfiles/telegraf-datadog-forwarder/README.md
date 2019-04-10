# Telegraf metric forwarder

This is a docker image that contains a Telegraf client which receives input on StatsD or Influx format
and transmits it to DataDog.

## Usage

In docker-compose.yml, add the following service wherever you want your stats monitored.

```yaml
services:
  telegraf-datadog-forwarder:
    image: kinecosystem/telegraf-datadog-forwarder:latest
    restart: always
    environment:
      DATADOG_API_KEY: "<api key>"
    logging:
      driver: json-file
      options:
        max-size: 100m
        max-file: "3"
```

