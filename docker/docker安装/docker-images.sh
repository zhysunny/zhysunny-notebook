#!/usr/bin/bash

# Author      : zhysunny
# Date        : 2020/7/30 0:48
# Description : 下载docker镜像

echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1
docker pull centos:7
docker pull redis:5.0.4
docker pull mysql:5.7
docker pull zookeeper:3.4.14
docker pull gitlab/gitlab-ce:11.9.9-ce.0
docker pull kong:1.1.0
docker pull kong:1.5.1
docker pull elasticsearch:7.5.1
docker pull logstash:7.5.1
docker pull kibana:7.5.1
docker pull docker.elastic.co/beats/filebeat:7.5.1