#!/bin/sh

set -ev

printf '0\n' > /proc/sys/net/ipv4/tcp_sack 

printf 'net.ipv4.tcp_sack=0\n' >> /etc/sysctl.conf
