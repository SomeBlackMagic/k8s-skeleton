#!/bin/bash

server_list=$(cat $1/inventory.ini | grep ansible_host | cut -f2 -d '=')

for server in ${server_list[@]}
do
    ssh root@$server 'apt update && apt install -y cifs-utils nfs-common open-iscsi'
done
