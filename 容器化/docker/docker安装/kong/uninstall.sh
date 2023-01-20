#!/usr/bin/bash

# Author      : zhysunny
# Date        : 2020/7/29 23:42
# Description : 卸载kong

docker stop konga-prepare
docker rm konga-prepare
docker stop konga
docker rm konga
docker stop kong-migration
docker rm kong-migration
docker stop kong-database
docker rm kong-database