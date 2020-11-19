#!/bin/bash
ip addr show tun0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1 > /home/media/vpn
ip addr show eno1 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1 > /home/media/net
dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}' > /home/media/exter
