#!/usr/bin/python

import argparse
import requests
import json
import re
import time

# Prometheus client library
from prometheus_client import start_http_server
from prometheus_client.core import GaugeMetricFamily, CounterMetricFamily, SummaryMetricFamily, REGISTRY

parser = argparse.ArgumentParser(description='simple stellar-core Prometheus exporter/scraper')
parser.add_argument('--uri', type=str,
                    help='core metrics uri, default: http://stellar-core:11626/metrics',
                    default='http://stellar-core:11626/metrics')
parser.add_argument('--port', type=int,
                    help='HTTP bind port, default: 9473',
                    default=9473)
args = parser.parse_args()

def add_summary_metric(summary, values, labels):
  summary.add_sample(summary.name + '_count', labels=labels, value=values['count'])
  summary.add_sample(summary.name + '_sum', labels=labels, value=(values['mean'] * values['count']))
  summary.add_sample(summary.name, labels={**labels, 'quantile':'0'}, value=values['min'])
  summary.add_sample(summary.name, labels={**labels, 'quantile':'0.5'}, value=values['median'])
  summary.add_sample(summary.name, labels={**labels, 'quantile':'0.75'}, value=values['75%'])
  summary.add_sample(summary.name, labels={**labels, 'quantile':'0.95'}, value=values['95%'])
  summary.add_sample(summary.name, labels={**labels, 'quantile':'0.98'}, value=values['98%'])
  summary.add_sample(summary.name, labels={**labels, 'quantile':'0.99'}, value=values['99%'])
  summary.add_sample(summary.name, labels={**labels, 'quantile':'0.999'}, value=values['99.9%'])
  summary.add_sample(summary.name, labels={**labels, 'quantile':'1'}, value=values['max'])


class Re(object):
  def __init__(self):
    self.last_match = None
  def match(self,pattern,text):
    self.last_match = re.match(pattern,text)
    return self.last_match
  def search(self,pattern,text):
    self.last_match = re.search(pattern,text)
    return self.last_match

class StellarCoreCollector(object):

  def collect(self):
    response = requests.get(args.uri)
    json = response.json()
    metrics = json['metrics']

    database_summary = SummaryMetricFamily("stellar_database_operations_ms", "Execution time of stellar-core DB operations")
    operation_counter = CounterMetricFamily("stellar_operations", "Stellar operations stats", labels=['operation', 'event'])
    history_events_counter = CounterMetricFamily("stellar_history_operations", "Counts operations with history arthive", labels=['operation', 'event'])
    ledger_entry_counter = CounterMetricFamily("stellar_ledger_entry_changes", "Counts the operations with ledger entries", labels=['entry', 'event'])

    gre = Re()
    for name, metric in metrics.items():
      if gre.match(r'^database[.](insert|select|delete|update)[.]([^.]+)$', name):
        op = gre.last_match.group(1)
        table = gre.last_match.group(2)
        add_summary_metric(database_summary, metric, { 'operation': op, 'table': table })
      elif gre.match(r'^op-([^.]+)[.]([^.]+)[.]([^.]+)$', name):
        op = gre.last_match.group(1)
        status = gre.last_match.group(2)
        event = gre.last_match.group(3)
        if op == "create-offer": op = "manage-offer"
        elif op == "merge": op = "merge-account"
        if event == "low reserve": event = "low-reserve"
        event = "success" if status == "success" else f'{status}.{event}'
        operation_counter.add_metric([op, event], metric['count'])
      elif gre.match(r'^history[.]([^.]+)[.]([^.]+)$', name) and metric['type'] == 'meter':
        op = gre.last_match.group(1)
        event = gre.last_match.group(2)
        history_events_counter.add_metric([op, event], metric['count'])
      elif gre.match(r'^ledger[.](account|data|offer|trust)[.](add|delete|modify)$', name) and metric['type'] == 'meter':
        entry = gre.last_match.group(1)
        event = gre.last_match.group(2)
        ledger_entry_counter.add_metric([entry, event], metric['count'])
      else:
        new_name = re.sub(r'\.|-|\s', '_', name).lower()
        descr = f'Generated from libmedida import (metric={name}, type={metric["type"]})'

        if metric['type'] == 'timer':
          summary = SummaryMetricFamily(new_name, descr)
          add_summary_metric(summary, metric, {})
          yield summary
        elif metric['type'] == 'counter':
          # we have a counter, this is a Prometheus Gauge
          yield GaugeMetricFamily(new_name, descr, value=metric['count'])
        elif metric['type'] == 'meter':
          yield CounterMetricFamily(new_name, descr, value=metric['count'])

    yield database_summary
    yield operation_counter
    yield history_events_counter
    yield ledger_entry_counter

if __name__ == "__main__":
  REGISTRY.register(StellarCoreCollector())
  start_http_server(args.port)
  while True: time.sleep(1)
