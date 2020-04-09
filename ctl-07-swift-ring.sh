#!/bin/bash
#Custom by Le Nam

source functions.sh
source info_config.sh

# Create ring account
swift_create_account_ring () {
	echocolor "Install account ring"
	sleep 3

	cd /etc/swift

	swift-ring-builder account.builder create 10 1 1

	swift-ring-builder account.builder add --region 1 --zone 1 --ip $STR1_MGNT_IP --port 6202 --device sdc --weight 100
	swift-ring-builder account.builder add --region 1 --zone 1 --ip $STR1_MGNT_IP --port 6202 --device sdd --weight 100

	swift-ring-builder account.builder
	swift-ring-builder account.builder rebalance
	echocolor "Done install account ring"
}

# Create container ring
swift_create_container_ring () {
	echocolor "Install container ring"
	sleep 3

	cd /etc/swift
	swift-ring-builder container.builder create 10 1 1

	swift-ring-builder container.builder add --region 1 --zone 1 --ip $STR1_MGNT_IP --port 6201 --device sdc --weight 100
	swift-ring-builder container.builder add --region 1 --zone 1 --ip $STR1_MGNT_IP --port 6201 --device sdd --weight 100
	
	swift-ring-builder container.builder
	swift-ring-builder container.builder rebalance
	echocolor "Done install container ring"
}

# Create object ring
swift_create_object_ring () {
	echocolor "Create object ring"
	sleep 3

	cd /etc/swift
	swift-ring-builder object.builder create 10 1 1

	swift-ring-builder object.builder add --region 1 --zone 1 --ip $STR1_MGNT_IP --port 6200 --device sdc --weight 100
	swift-ring-builder object.builder add --region 1 --zone 1 --ip $STR1_MGNT_IP --port 6200 --device sdd --weight 100

	swift-ring-builder object.builder
	swift-ring-builder object.builder rebalance
	echocolor "Done create object ring"
}

# Create swift.config
swift_install (){
	echocolor "Create swift.conf"
	sleep 3

	curl -o /etc/swift/swift.conf https://opendev.org/openstack/swift/raw/branch/stable/stein/etc/swift.conf-sample

	swiftfile=/etc/swift/swift.conf
	ops_add $swiftfile swift-hash swift_hash_path_suffix openstack
	ops_add $swiftfile swift-hash swift_hash_path_prefix openstack

	chown -R root:swift /etc/swift
	service memcached restart
	service swift-proxy restart
	echocolor "Done create swift config"
}

#######################
###Execute functions###
#######################

# Create ring account
swift_create_account_ring

# Create container ring
swift_create_container_ring

# Create object ring
swift_create_object_ring

# Create swift.config
swift_install