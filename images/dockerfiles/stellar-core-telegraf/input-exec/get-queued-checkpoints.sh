#!/bin/sh
result=$(curl stellar-core:11626/info|jq .'info.status'|grep "Publishing.* q"|awk '{print $2}')
if [ "$result" = "" ]; then
   queued=0
else
   queued=$result
fi
echo 'queued_checkpoints num='$queued
