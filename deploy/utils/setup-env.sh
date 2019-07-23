#!/usr/bin/env bash
sudo rm -rf /data/postgresql
sudo rm -rf /data/stellar-core/buckets
sudo docker-compose -f /data/docker-compose.yml up -d stellar-core-db
sudo docker-compose -f /data/docker-compose.yml run --rm stellar-core --newdb
sudo docker-compose -f /data/docker-compose.yml run --rm stellar-core --forcescp
sudo docker-compose -f /data/docker-compose.yml run --rm stellar-core --newhist local
sudo docker-compose -f /data/docker-compose.yml up -d