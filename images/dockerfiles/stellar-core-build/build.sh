#!/usr/bin/env bash
set -e
set -x

cd /stellar-core

# prepare
./autogen.sh
./configure --enable-asan --enable-sdfprefs CXXFLAGS=-w

# make format

# build
make -j $(nproc) check && make -j $(nproc)
# test
# export ALL_VERSIONS=1
# make check
