#!/bin/bash
ip addr show tun0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1 > /home/media/vpn
ip addr show eno1 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1 > /home/media/net
dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}' > /home/media/exter
ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//"

Here is best solution
ip route get 8.8.8.8 | awk -- '{printf $5}'
or
echo $(ip route get 8.8.8.8 | awk -- '{printf $5}')
in bash script you can declare main_interface and use anywhere as $main_interface
main_interface=$(ip route get 8.8.8.8 | awk -- '{printf $5}')
