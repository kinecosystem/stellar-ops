# Stellar Core Telegraf

This is a docker image for a telegraf client that monitors a Stellar core application

## Usage

In docker-compose, add the following service next to the stellar-core one.

```yaml
services:
  stellar-core-telegraf:
    environment:
      NODE_NAME: "<insert node name here>"
      NETWORK_NAME: "<insert stellar-network name here>"
    image: kinecosystem/stellar-core-telegraf:latest
    links:
      - "stellar-core:stellar-core"
    restart: always
    logging:
      driver: json-file
      options:
        max-size: 100m
        max-file: "3"
```

