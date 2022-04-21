#!/bin/bash

# 同步版本信息
function SYNC_VERSION () {
    sync_info=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep "aptos_state_sync_version{type=\"synced\"}"`
    echo "查询同步版本信息: ${sync_info}"
}

# 出站网络信息
function OUTBOUND_NETWORK () {
    network_info=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep "aptos_connections{direction=\"outbound\""`
    echo "出站网络连接应大于0: ${network_info}"
}

function DISK_DATA () {
    disk_info=`df -h  |grep docker |awk '{print $2,$3}'`
    echo "磁盘资源使用情况(总量\使用量): ${disk_info}"
}

# 循环查询
function LOOK_SEARCH () {
    while true
        do
            clear
            curl -k 'https://www.skyviewcrypto.io/aptos-full-node/docker_view'
            SYNC_VERSION
            OUTBOUND_NETWORK
            DISK_DATA
            echo "等待5秒清屏刷新"
            sleep 5
        done
}

LOOK_SEARCH
