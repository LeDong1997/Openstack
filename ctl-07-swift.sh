#!/bin/bash
#Custom by Le Nam

source functions.sh
source info_config.sh


source /home/openstack/Stein/ctl-07-swift-proxy-install.sh

# Install swift in storage node
source /home/openstack/Stein/str-07-swift-install.sh

# Install swift in controller node
source /home/openstack/Stein/ctl-07-swift-ring.sh

# Verify install swift service
verify_swift_install (){
	cd ~/Stein
	swift-init all start
	echocolor "Verify install swift service"
	sleep 3
	source /root/demo-openrc
	swift stat
	openstack container create container1
	echo "IT6500-Cloud Computing" >> test-object.txt
	openstack object create container1 test-object.txt
	openstack object list container1
	mkdir Downloads && cd Downloads && openstack object save container1 test-object.txt
	echocolor "Done verify install swift service"
}

#######################
###Execute functions###
#######################

# Verify install Cinder service
verify_swift_install