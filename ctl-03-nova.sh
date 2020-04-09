#!/bin/bash
#Custom by Le Nam

source functions.sh
source info_config.sh

# Install nova service in controller node
source /home/openstack/Stein/ctl-03-nova-install.sh
# Install nova service in compute node
source /home/openstack/Stein/com-03-nova-install.sh

# Function Discover compute hosts
nova_discover_compute_host (){
	source /root/admin-openrc
	openstack compute service list --service nova-compute
	echocolor "Discover compute hosts"
	sleep 3
	su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
	echocolor "Done discover compute hosts"
}

# Function verify install nova service
nova_verify_install(){
	echocolor "Verify Install Nova Service"
	sleep 3

	source /root/admin-openrc
	openstack compute service list
	openstack catalog list
	openstack image list
	nova-status upgrade check
	echocolor "Done verify Nova service"
}

#######################
###Execute functions###
#######################

# Discover compute hosts
nova_discover_compute_host

# Verify install nova service
nova_verify_install
