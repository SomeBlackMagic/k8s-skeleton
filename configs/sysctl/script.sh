#!/bin/bash

server_list=$(cat $1/inventory.ini | grep ansible_host | cut -f2 -d '=')

for server in ${server_list[@]}
do
  if [ "$server" != "ip" ] ; then
    scp configs/sysctl/sysctl.conf root@$server:/etc/sysctl.conf
    ssh root@$server 'sysctl -p'
  fi
done