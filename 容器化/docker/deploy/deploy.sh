#!/usr/bin/bash

# Author      : 章云
# Date        : 2020/6/2 23:59
# Description : docker 镜像

CENTOS_VERSION=8.1.1911

function Usage(){
    echo "sh `basename $0` centos"
}

function pull_centos(){
    EXIST_IMAGE=`docker images | grep centos | grep ${CENTOS_VERSION}`
    if [[ -z ${EXIST_IMAGE} ]]; then
        echo ""
        CENTOS_DOCKER_FILE="centos-docker-${CENTOS_VERSION}.tar.gz"
        if [[ -f ${CENTOS_DOCKER_FILE} ]]; then
            echo "导入本地镜像"
            docker load < ${CENTOS_DOCKER_FILE}
        else
            echo "下载远程镜像并导出本地"
            docker pull centos:${CENTOS_VERSION}
            docker save -o centos-docker-${CENTOS_VERSION}.tar.gz centos:${CENTOS_VERSION}
        fi
        echo ""
    fi
}

COMMAND=$1
shift
case ${COMMAND} in
    centos )
        pull_centos
        ;;
    * )
		Usage
        exit 1
        ;;
esac
