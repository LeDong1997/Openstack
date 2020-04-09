#!/bin/bash
#Custom by Le Nam

source functions.sh
source info_config.sh

# Function config hostname
config_hostname () {
	echocolor "Start config hostname for Controller Node"
	# echo "$HOST_CTL" > /etc/hostname
	# hostnamectl set-hostname $HOST_CTL
	echo "$HOST_NAME" > /etc/hostname
	hostnamectl set-hostname $HOST_NAME

	cat << EOF >/etc/hosts
127.0.0.1	localhost

$CTL_MGNT_IP	$HOST_NAME
$CTL_MGNT_IP	$HOST_CTL
$COM1_MGNT_IP	$HOST_COM1
$STR1_MGNT_IP	$HOST_STR1
EOF
	echocolor "Done config hostname"
}

# Function install ifupdown package
install_ifupdown () {
	echocolor "Start install ifupdown package"
	apt-get update
	apt-get install -y ifupdown
	echocolor "Done install ifupdown package"
}

# Function install DNS service
install_dns_service () {
	echocolor "Start install dns service"
	apt-get update
	apt-get install -y resolvconf
	service resolvconf restart

	# Config DNS service
	dns_file=/etc/resolvconf/resolv.conf.d/head
	echo "nameserver 8.8.8.8" >> $dns_file
	echo "nameserver 1.1.1.1" >> $dns_file
	echo "nameserver 8.8.4.4" >> $dns_file

	service resolvconf restart

	echocolor "Done install dns service"
}

# Function remove netplan package
remove_netplan () {
	echocolor "Start remove netplan package"
	# Remove config
	apt-get -y purge netplan.io
	# Remove directory netplan service
	rm -rf /etc/netplan
	rm -rf /usr/share/netplan
	echocolor "Done remove netplan package"
}

# Function config IP address
config_ip () {
	echocolor "Start config ip address"
	cat << EOF > /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*
# Loopback network interface
auto lo
iface lo inet loopback

# Management (internal) network interface
auto $CTL_MGNT_IF
iface $CTL_MGNT_IF inet static
address $CTL_MGNT_IP
netmask $CTL_MGNT_NETMASK

# Provider network interface
auto $CTL_MAP_IF
iface $CTL_MAP_IF inet manual
up ip link set dev $CTL_MAP_IF up
down ip link set dev $CTL_MAP_IF down

# External (NAT) network interface
auto $CTL_EXT_IF
iface $CTL_EXT_IF inet static
address $CTL_EXT_IP
netmask $CTL_EXT_NETMASK
gateway $GATEWAY_EXT_IP
dns-nameservers 1.1.1.1 8.8.8.8
EOF

	echocolor "Done config ip address for Controller Node"
	echocolor "Start reboot system to update network"
	# Reset network interface
	ip a flush $CTL_EXT_IF
	ip a flush $CTL_MGNT_IF
	ip r del default
	ifdown -a && ifup -a
	service networking restart
}


#######################
###Execute functions###
#######################

# Config Controller node
echocolor "Config Controller node"
sleep 3

## Config hostname
config_hostname

## Install ifupdown
install_ifupdown

## Install DNS service
install_dns_service

## Remove netplan package
remove_netplan

## Config ip address
config_ip

reboot