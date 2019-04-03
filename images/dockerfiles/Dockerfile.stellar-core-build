# TODO: ccache, run as calling user instead of root
FROM ubuntu:18.04

RUN BUILD_DEPS="git build-essential pkg-config autoconf automake libtool bison flex libpq-dev gcc-6 g++-6 cpp-6 pandoc perl postgresql-client"; \
    apt-get -qq update \
    && apt-get install -qq software-properties-common \
    && add-apt-repository ppa:ubuntu-toolchain-r/test \
    && apt-get -qq update \
    && apt-get -qq install $BUILD_DEPS

RUN mkdir -p /stellar-core
WORKDIR /stellar-core
VOLUME /stellar-core

COPY dockerfiles/stellar-core-build/build.sh /

CMD /build.sh
