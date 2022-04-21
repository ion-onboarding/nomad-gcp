#!/usr/bin/env bash

# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# add ubuntu to docker group
usermod -aG docker ubuntu