#!/bin/bash
# this script takes a filename of DNS addresses of cores and attempts to create a connection to them. 
# the retval is the number of unsuccessful connections.

fail=0
pass=0
while IFS='' read -r line || [[ -n "$line" ]]; do
    curl $line:11625 -s --connect-timeout 2 # curl connection timeout (seconds)
    res=$?
    if test "$res" != "52"; then
       ((fail++))
    else
       ((pass++))
    fi
done < "$1"
echo 'connectivity_check cores_failed='$fail
