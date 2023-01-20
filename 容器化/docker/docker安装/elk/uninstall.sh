#!/usr/bin/bash

# Author      : zhysunny
# Date        : 2020/7/29 23:42
# Description : 卸载elk

docker stop logstash
docker rm logstash
docker stop kibana
docker rm kibana
docker stop es-slave1
docker rm es-slave1
docker stop es-master
docker rm es-master