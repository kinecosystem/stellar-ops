#!/bin/bash
# count the number of peers with an id that does NOT begin with 'G' == the number of named peers.

set -e

result=$(curl stellar-core:11626/peers|grep '"id"'|grep -v '\"G'|wc -l)

printf 'core_named_peers count=%s\n' $result
