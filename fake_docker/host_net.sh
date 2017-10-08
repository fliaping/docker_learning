#!/usr/bin/env bash

set -x

if [[ $EUID -ne 0 ]]; then
    echo "You must be root to run this script"
    exit 1
fi

NS=$1
VETH="veth0"
VPEER="veth0.1"
VETH_ADDR="192.168.8.1"
VPEER_ADDR="192.168.8.2"

if [ ! -n "$1" ]; then
    echo "IS NULL"

    # Enable IP-forwarding.
    echo 1 > /proc/sys/net/ipv4/ip_forward

    # Flush forward rules.
    iptables -P FORWARD DROP
    iptables -F FORWARD

    # Flush nat rules.
    iptables -t nat -F

    # Enable masquerading of 10.200.1.0.
    iptables -t nat -A POSTROUTING -s ${VPEER_ADDR}/24 -o eth0 -j MASQUERADE

    iptables -A FORWARD -i eth0 -o ${VETH} -j ACCEPT
    iptables -A FORWARD -o eth0 -i ${VETH} -j ACCEPT

else
    echo "NOT NULL"

     # Remove namespace if it exists.
    ip netns del $NS &>/dev/null

    # Create veth link.
    ip link add ${VETH} type veth peer name ${VPEER}

    # Add peer-1 to NS.
    ip link set ${VPEER} netns $NS

    # Setup IP address of ${VETH}.
    ip addr add ${VETH_ADDR}/24 dev ${VETH}
    ip link set ${VETH} up

fi

