#!/bin/bash -xe

MYSQL_EXT_PORT='33060'
MYSQL_ROOT_PWD='1'
PROJNAME=chess
MYSQL_CONTAINER_NAME="${PROJNAME}_mysql"

# verify that all soft installed
test $(which docker)
test $(which mysql)

docker container stop $MYSQL_CONTAINER_NAME || true
docker container rm $MYSQL_CONTAINER_NAME || true
docker container run -d \
	--name $MYSQL_CONTAINER_NAME \
	-e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PWD \
	-v ${PROJNAME}_mysql:/var/lib/mysql \
	-p ${MYSQL_EXT_PORT}:3306 \
	mysql 

sleep 10

mv ~/.my.cnf ~/.my.cnf_$(date +%F) || true
cat >> ~/.my.cnf << EOF
[client]
host = 127.0.0.1
port = 3306
user=root
password=${MYSQL_ROOT_PWD}
EOF


mysql -e "create database if not exists $PROJNAME"
mysql -e "use $PROJNAME"

