#!/usr/bin/env ash

set -x

ip link set dev lo up

ip link set dev veth0.1 name eth0

ip address add dev eth0 192.168.8.2/24


ip link set eth0 up

ip route add default via 192.168.8.1

echo "nameserver 114.114.114.114" > /etc/resolv.conf


mkdir -p /var/lock

touch /var/lock/opkg.lock
