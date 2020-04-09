#!/bin/bash
#Custom by Le Nam

###########################################
#### Set local variables  for scripts #####
###########################################

echocolor "Set local variable for scripts"
sleep 3

# Network model (provider or selfservice)
network_model=selfservice

#  IP address variable and Hostname variable
## Assigning IP for Controller node
### Management IP
CTL_MGNT_IF=eth0
CTL_MGNT_IP=10.0.0.10
CTL_MGNT_NETMASK=255.255.255.0
### Internet IP
CTL_EXT_IF=eth2
CTL_EXT_IP=192.168.10.100
CTL_EXT_NETMASK=255.255.255.0
### Selfservice map interface
CTL_MAP_IF=eth1

## Assigning IP for Compute node
### Management IP
COM1_MGNT_IF=eth0
COM1_MGNT_IP=10.0.0.10
COM1_MGNT_NETMASK=255.255.255.0
### Internet IP
COM1_EXT_IF=eth2
COM1_EXT_IP=192.168.10.100
COM1_EXT_NETMASK=255.255.255.0

## Assigning IP for Storage node
### Management IP
STR1_MGNT_IF=eth0
STR1_MGNT_IP=10.0.0.10
STR1_MGNT_NETMASK=255.255.255.0
### Internet IP
STR1_EXT_IF=eth2
STR1_EXT_IP=192.168.10.100
STR1_EXT_NETMASK=255.255.255.0

## Gateway for EXT network
GATEWAY_EXT_IP=192.168.10.2
CIDR_EXT=192.168.10.0/24
CIDR_MGNT=10.0.0.0/24

## Hostname variable
HOST_NAME=allinone
HOST_CTL=controller
HOST_COM1=compute
HOST_STR1=storage

# Password variables
DEFAULT_PASS="openstack"

## Password for MariaDB and Openstack service
ADMIN_PASS=$DEFAULT_PASS
DEMO_PASS=$DEFAULT_PASS
ROOT_DBPASS=$DEFAULT_PASS
RABBIT_PASS=$DEFAULT_PASS
KEYSTONE_DBPASS=$DEFAULT_PASS
GLANCE_DBPASS=$DEFAULT_PASS
GLANCE_PASS=$DEFAULT_PASS
NOVA_DBPASS=$DEFAULT_PASS
NOVA_PASS=$DEFAULT_PASS
PLACEMENT_PASS=$DEFAULT_PASS
METADATA_SECRET=$DEFAULT_PASS
NEUTRON_DBPASS=$DEFAULT_PASS
NEUTRON_PASS=$DEFAULT_PASS
CINDER_DBPASS=$DEFAULT_PASS
CINDER_PASS=$DEFAULT_PASS
DASH_DBPASS=$DEFAULT_PASS
SWIFT_PASS=$DEFAULT_PASS
