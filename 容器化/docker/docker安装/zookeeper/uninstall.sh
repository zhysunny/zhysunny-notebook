#!/usr/bin/bash

# Author      : zhysunny
# Date        : 2020/7/29 23:42
# Description : 卸载redis

docker stop zookeeper1
docker rm zookeeper1
docker stop zookeeper2
docker rm zookeeper2