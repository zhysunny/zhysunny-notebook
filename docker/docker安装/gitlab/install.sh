#!/usr/bin/bash

# Author      : zhysunny
# Date        : 2020/7/29 23:41
# Description : 安装gitlab

rm -rf /opt/gitlab
docker-compose -f gitlab.yml up -d
