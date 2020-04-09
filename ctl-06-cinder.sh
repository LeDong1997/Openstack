#!/bin/bash
#Custom by Le Nam

source functions.sh
source info_config.sh

# Install cinder in block storage node
source /home/openstack/Stein/str-06-cinder-install.sh

# Install cinder in controller node
source /home/openstack/Stein/ctl-06-cinder-install.sh

# Verify install Cinder service
verify_cinder_install (){
	echocolor "Verify install Cinder service"
	sleep 3
	source /root/admin-openrc
	openstack volume service list
	echocolor "Done verify install Cinder service"
}

#######################
###Execute functions###
#######################

# Verify install Cinder service
verify_cinder_install
