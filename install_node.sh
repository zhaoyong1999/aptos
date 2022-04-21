#!/bin/bash


url='https://www.skyviewcrypto.io/aptos-full-node/'

function VERIFY () {
    curl -k 'https://www.skyviewcrypto.io/aptos-full-node/docker_view'
    read -p "plase input password:" input_password
    number_password=`expr length ${input_password}`
    if [ ${number_password} -eq 42 ]
        then
            echo "长度检验完成"
        else
            echo "校验码无效，请前往SkyView Discord获取校验码"
            exit 1
     fi

    password_file='verify.txt'
    curl -Ok  "${url}${password_file}" 2&>1 /dev/null
    cat ${password_file} | grep -q ${input_password}
    if [ $? -eq 0 ];then
	echo "校验码有效"

    else
       echo "校验码无效，请前往SkyView Discord获取校验码"
       exit 1
    fi
}


function INSTALL_DOCKER () {
    which docker
    if [ $? -eq 0 ]
        then
            echo "docker is installed"
        else
            echo "start install docker"
            curl -sSL https://get.daocloud.io/docker |sh 
    fi
    systemctl start docker
}


function INSTALL_DOCKER_COMPOSE () {
    which docker-compose
    if [ $? -eq 0 ]
        then
             echo "docker-compose is installed"
        else
             echo "start install docker-compose"
             sudo curl -L "https://github.com/docker/compose/releases/download/v2.2.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
             sudo chmod +x /usr/local/bin/docker-compose && sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose && docker-compose --version
    fi
	
}


function DOWNLOAD_INSTALL_FILE () {
    url='https://www.skyviewcrypto.io/aptos-full-node/'
    echo "开始下载 FULL NODE文件"

    public_full_node='public_full_node.yaml'
    if [ -f ${public_full_node} ]
        then
            echo "文件已存在,直接跳过: ${public_full_node}"
        else
            curl -Ok "${url}${public_full_node}"
        fi

    genesis='https://devnet.aptoslabs.com/genesis.blob'
    curl -Ok ${genesis}
   # if [ -f ${genesis} ]
   #     then
   #         echo "文件已存在,直接跳过: ${genesis}"
   #     else
   #         curl -Ok "${url}${genesis}"
   #     fi

    waypoint='https://devnet.aptoslabs.com/waypoint.txt'
    curl -Ok ${waypoint}
   # if [ -f ${waypoint} ]
   #     then
   #         echo "文件已存在,直接跳过: ${waypoint}"
   #     else
   #         curl -Ok "${url}${waypoint}"
   #     fi

    COMPOSE='docker-compose.yaml'
    curl -Ok "${url}${COMPOSE}"
    echo "下载FULL NODE文件完成"
}


function DOCKER_UP () {
    echo "start docker compose up"
    docker-compose up
}


function DOCKER_TOOLS () {
    docker_tools=`docker ps -a |grep 'aptoslab/tools:devnet' |awk '{print $1}'`
    if [ ! -z  ${docker_tools} ]
        then
            echo "tools已存在,启动服务"
            docker ps -a |grep 'aptoslab/tools:devnet' |awk '{print $1}' |xargs docker start  >> /dev/null
        else
            docker run -itd aptoslab/tools:devnet sh 
        fi
}


function TOKEN () {
    if [ -f /private.key ]
        then
            echo "跳过创建私钥步骤，私钥文件已存在于/private.key"
        else

            name=`docker ps |grep 'aptoslab/tools:devnet' |awk '{print $1}'` 
            docker exec -it $name aptos-operational-tool generate-key --encoding hex --key-type x25519 --key-file /private-key.txt >> /dev/null
            private_result=`docker exec -it $name cat /private-key.txt`
            echo $private_result > /private.key
            docker exec -it $name  aptos-operational-tool extract-peer-from-file --encoding hex --key-file /private-key.txt --output-file /peer-info.yaml > /tmp/peer.result
    fi   
    private_result=`cat /private.key`
    sed -i "s/<PRIVATE_KEY>/${private_result}/g" ./public_full_node.yaml 
    peer_result=`tail -n 6 /tmp/peer.result |head -n 1 | sed  's/[[:blank:]]//g' | tr -d '\r'`
    sed -i "s/\"<PEER_ID>\"/${peer_result}/g" ./public_full_node.yaml
    echo "已替换私钥成功，你的私钥存储在/private.key"
    echo "开始同步中..."
    sleep 5
}


VERIFY
INSTALL_DOCKER
INSTALL_DOCKER_COMPOSE
DOWNLOAD_INSTALL_FILE
DOCKER_TOOLS
TOKEN
DOCKER_UP
