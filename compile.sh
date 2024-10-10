#!/bin/sh

apt update && apt install -y libpcap-dev \
    libhyperscan-dev

docker build --output=./dist/caronte --target=exporter --file=Dockerfile.builder .
