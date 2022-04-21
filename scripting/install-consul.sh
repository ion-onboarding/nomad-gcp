#!/usr/bin/env bash

# install latest consul version
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq consul

# empty default config
echo "" | tee /etc/consul.d/consul.hcl