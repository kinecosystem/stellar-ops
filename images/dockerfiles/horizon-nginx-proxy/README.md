# Horizon Nginx Proxy

In the of an SSE event, Horizon may not send any data for 60+ seconds.
This causes AWS ELB to cut the connection and return HTTP 504,
which in turn looks like an error.

See the following issue for more information: [stellar/go/issues/154](https://github.com/stellar/go/issues/154)

With this docker image we can proxy requests to Horizon,
timeout requests on our own instead or letting ELB do it,
and send 200 instead of 504 for SSE reqests (only requests with the header "text/event-stream" will return as 200 instead of 504)

This nginx image contains a dyanmic module for emitting statsd stats. The stats emitted include the following:
- number of requests served per method
- the duration of requests per method

note that you can configure the sample rate as well as the prefix attached
to the metrices, but the destination is hard-coded to localhost (port 8125), where your statsd/telegraf should reside. This image should be used in conjugation with the horizon-telegraf image, which forwards the statsd stats as influx-db metrics to the metrics intake point.

## Usage

In docker-compose.yml:

```yaml
version: "3"

horizon:
  image: kinecosystem/horizon
  # ...

horizon-nginx-proxy:
  image: kinecosystem/horizon-nginx-statsd:v1  # or any other version
  ports:
    - 8000:8000
  environment:
    STATSD_SAMPLE_RATE: 100
    STATSD_METRIC_PREFIX: 'my-node'
    PROXY_LISTEN_PORT: 8000
    PROXY_READ_TIMEOUT: 10
    PROXY_PASS_URL: http://horizon:8000
```

## TODO
Change server parameters:  
https://serverfault.com/questions/787919/optimal-value-for-nginx-worker-connections  
https://stackoverflow.com/questions/11342167/how-to-increase-ulimit-on-amazon-ec2-instance  
https://serverfault.com/questions/48717/practical-maximum-open-file-descriptors-ulimit-n-for-a-high-volume-system  
ubik/blob/master/playbooks/roles/network-server/files/etc/sysctl.conf  
