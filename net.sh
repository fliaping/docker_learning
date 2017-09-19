#!/usr/bin/env bash

export C_PID=22152

echo $C_PID

## 首先，我们先增加一个网桥lxcbr0，模仿docker0
brctl addbr lxcbr0
brctl stp lxcbr0 off
ifconfig lxcbr0 192.168.10.1/24 up #为网桥设置IP地址

## 接下来，我们要创建一个network namespace - ns1

# 增加一个namesapce 命令为 ns1 （使用ip netns add命令）
ip netns add $C_PID

# 激活namespace中的loopback，即127.0.0.1（使用ip netns exec ns1来操作ns1中的命令）
ip netns exec $C_PID ip link set dev lo up

## 然后，我们需要增加一对虚拟网卡

# 增加一个pair虚拟网卡，注意其中的veth类型，其中一个网卡要按进容器中
ip link add veth-$C_PID type veth peer name lxcbr0.1

# 把 veth-ns1 按到namespace ns1中，这样容器中就会有一个新的网卡了
ip link set veth-$C_PID netns $C_PID

# 把容器里的 veth-ns1改名为 eth0 （容器外会冲突，容器内就不会了）
ip netns exec $C_PID ip link set dev veth-$C_PID name eth0

# 为容器中的网卡分配一个IP地址，并激活它
ip netns exec $C_PID ifconfig eth0 192.168.10.11/24 up


# 上面我们把veth-ns1这个网卡按到了容器中，然后我们要把lxcbr0.1添加上网桥上
brctl addif lxcbr0 lxcbr0.1

# 为容器增加一个路由规则，让容器可以访问外面的网络
ip netns exec $C_PID ip route add default via 192.168.10.1

# 在/etc/netns下创建network namespce名称为ns1的目录，
# 然后为这个namespace设置resolv.conf，这样，容器内就可以访问域名了
mkdir -p /etc/netns/$C_PID
echo "nameserver 114.114.114.114" > /etc/netns/ns1/resolv.conf
