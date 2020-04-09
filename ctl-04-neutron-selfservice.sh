#!/bin/bash
#Custom by Le Nam

source functions.sh
source info_config.sh

# Install neutron in controller node
source /home/openstack/Setin/ctl-04-neutron-selfservice-install.sh
# Install neutron in compute node
source /home/openstack/Setin/com-04-neutron-selfservice-install.sh

# Function Verify install neutron service
neutron_verify_install (){
	echocolor "Verify install neutron service"
	sleep 3
	source /root/admin-openrc
	openstack network agent list
	echocolor "Done Verify install neutron service"
}

#######################
###Execute functions###
#######################

# Verify install neutron service
neutron_verify_install
