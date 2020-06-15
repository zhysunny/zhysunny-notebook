# Author      : 章云
# Date        : 2020/6/15 23:47
# Description : nginx安装镜像

FROM centos:8.1.1911
MAINTAINER zhangyun
WORKDIR /opt/nginx

RUN rm -rf /etc/yum.repos.d/*
COPY CentOS-8-reg.repo /etc/yum.repos.d/CentOS-8-reg.repo
ADD nginx-1.18.0.tar.gz ./

RUN yum -y install gcc-c++