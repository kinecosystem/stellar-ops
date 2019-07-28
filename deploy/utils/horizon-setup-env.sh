#!/usr/bin/env bash
sudo rm -rf /data/postgresql
sudo rm -rf /data/horizon-volumes
sudo docker-compose -f /data/docker-compose.yml down
sudo docker-compose -f /data/docker-compose.yml up -d horizon-db
sleep 14
sudo docker-compose -f /data/docker-compose.yml run --rm horizon db init
sleep 2
sudo docker-compose -f /data/docker-compose.yml up -d