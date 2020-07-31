#!/usr/bin/bash

# Author      : zhysunny
# Date        : 2020/7/30 0:48
# Description : 下载docker镜像

echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1
docker pull centos:7
docker pull redis:5.0.4
docker pull mysql:5.7