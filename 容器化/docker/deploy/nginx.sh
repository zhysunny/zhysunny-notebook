FROM centos:8.1.1911
MAINTAINER zhysunny
WORKDIR /opt/nginx

RUN rm -rf /etc/yum.repos.d/*
COPY CentOS-8-reg.repo /etc/yum.repos.d/CentOS-8-reg.repo
ADD nginx-1.18.0.tar.gz ./

RUN yum downgrade -y glibc glibc-common libstdc++ libselinux libsemanage libsepol krb5-libs && \
    yum install -y zlib zlib-devel libselinux-devel libsepol-devel libkadm5 wget make gcc-c++ pcre pcre-devel openssl openssl-devel libtool && \
    cd nginx-${NGINX_VERSION} && ./configure --prefix=/usr/local/src/nginx-${NGINX_VERSION} && make && make install && \
    echo 'export PATH="$PATH:/usr/local/src/nginx-${NGINX_VERSION}/sbin"' >> ~/.bashrc && source ~/.bashrc && nginx -v

ENTRYPOINT ["sleep", "36000"]
