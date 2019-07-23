#!/usr/bin/env bash
sudo rm -rf /data/postgresql
sudo rm -rf /data/stellar-core/buckets
sudo docker-compose -f /data/docker-compose.yml up -d stellar-core-db
sleep 14
sudo docker-compose -f /data/docker-compose.yml run --rm stellar-core --newdb
sleep 2
sudo docker-compose -f /data/docker-compose.yml run --rm stellar-core --forcescp
sleep 2
sudo docker-compose -f /data/docker-compose.yml run --rm stellar-core --newhist local
sleep 2
sudo docker-compose -f /data/docker-compose.yml up -d