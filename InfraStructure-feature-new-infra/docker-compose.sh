#!/bin/bash

cd /tmp/
sudo docker build -t jenkins-master:0.1 -f Dockerfile.master .
sudo docker build -t jenkins-slave:0.1 -f Dockerfile.slave .
sudo docker build -t nginx-jenkins:0.1 -f Dockerfile.nginx.jenkins .
sudo docker-compose -f docker-compose.yml up -d
sudo docker-compose -f docker-compose-nginx-jenkins.yml up -d
