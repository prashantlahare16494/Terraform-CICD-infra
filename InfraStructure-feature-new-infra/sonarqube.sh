#!/bin/bash

cd /tmp/
sudo docker build -t nginx-sonarqube:0.1 -f Dockerfile.nginx.sonarqube .
sudo docker-compose -f docker-compose-sonarqube.yml up -d
sudo docker-compose -f docker-compose-nginx-sonarqube.yml up -d
