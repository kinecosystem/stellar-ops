
# Prometheus

Prometheus is an open-source systems monitoring and alerting toolkit
[enter link description here](https://prometheus.io)

We are using it to display Horizons and Core health on our site as time series graph on the kin.org website.

## Configuration
The Prometheus is running on docker-compose, installed on 2 instances (but not as a sync cluster, but rather two independent instances for high availability)
Configuration files for Prometheus are part of the project.

### Installation

 - VPC: Default Subnets: 2 private subnets, 2 public subnets 
 - Instances: 2 instances, each instance run on a different private subnet 
 - LoadBalancer: ALB with 1 hour stickiness 
 - Domain: Route53 record on kin.org from  [https://prometheus-dashboard.kin.org/graph](https://prometheus-dashboard.kin.org/graph) to the ALB.

## Monitoring dashboard
Instances run Telegraf for local monitoring.
Monitoring is forwarded to Datadog from the Telegraf forwarder.


## Alerts
Alerts exists on DataDog:

 - Disk space on instances
 - Load (5 minutes avg)
 - Access to the domain (Synthetics): [https://prometheus-dashboard.kin.org/graph](https://prometheus-dashboard.kin.org/graph)
