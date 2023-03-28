#!/bin/bash

cd /tmp/
sudo docker build -t nexus:latest -f Dockerfile.nexus .
sudo docker build -t nginx-nexus:0.1 -f Dockerfile.nginx.nexus .
sudo docker-compose -f docker-compose-nexus.yml up -d
sudo docker-compose -f docker-compose-nginx-nexus.yml up -d
