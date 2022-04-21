#!/usr/bin/env bash

# install latest nomad version
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nomad

# empty default config
echo "" | tee /etc/nomad.d/nomad.hcl