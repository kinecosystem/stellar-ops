#!/bin/bash
# this script takes a filename of DNS addresses of cores and attempts to open a TCP socket to them.
# it prints a metric representing the number of unsuccessful connections.

failed=0
passed=0

while IFS='' read -r line || [[ -n "$line" ]]; do
    if nc -zw 2 $line 11625 ; then ((passed++)) ; else ((failed++)) ; fi
done < "$1"

printf 'connectivity_check cores_failed=%d\n' $failed
