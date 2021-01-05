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
docker pull pantsel/konga:0.14.1
docker pull postgres:9.6
docker pull elasticsearch:7.5.1
docker pull logstash:7.5.1
docker pull kibana:7.5.1
docker pull docker.elastic.co/beats/filebeat:7.5.1

docker save -o elasticsearch-7.5.1.tar.gz elasticsearch:7.5.1
docker save -o logstash-7.5.1.tar.gz logstash:7.5.1
docker save -o kibana-7.5.1.tar.gz kibana:7.5.1
docker save -o filebeat-7.5.1.tar.gz docker.elastic.co/beats/filebeat:7.5.1
docker save -o redis-5.0.4.tar.gz redis:5.0.4
docker save -o mysql-5.7.tar.gz mysql:5.7
docker save -o zookeeper-3.4.14.tar.gz zookeeper:3.4.14
docker save -o gitlab-11.9.9-ce.0.tar.gz gitlab/gitlab-ce:11.9.9-ce.0
docker save -o kong-1.1.0.tar.gz kong:1.1.0
docker save -o kong-1.5.1.tar.gz kong:1.5.1
docker save -o postgres-9.6.tar.gz postgres:9.6
docker save -o konga-0.14.1.tar.gz pantsel/konga:0.14.1