#!/bin/bash
#Custom by Le Nam

source functions.sh
source info_config.sh

swift_pre_install () {
	echocolor "Pre install swift in Controller Node"
	source /root/admin-openrc
	openstack user create --domain default --password openstack swift
	openstack role add --project service --user swift admin

	openstack service create --name swift --description "OpenStack Object Storage" object-store
	openstack endpoint create --region RegionOne object-store public http://$HOST_CTL:8080/v1/AUTH_%\(project_id\)s
	openstack endpoint create --region RegionOne object-store internal http://$HOST_CTL:8080/v1/AUTH_%\(project_id\)s
	openstack endpoint create --region RegionOne object-store admin http://$HOST_CTL:8080/v1
	echocolor "Done pre install swift in Controller Node"
}

swift_proxy_install () {
	source /root/admin-openrc
	echocolor "Install swift proxy"
	apt-get install -y swift swift-proxy python3-swiftclient python3-keystonemiddleware python3-memcache python3-keystoneclient

	mkdir /etc/swift
	cd /etc/swift && curl -o /etc/swift/proxy-server.conf https://opendev.org/openstack/swift/raw/branch/stable/stein/etc/proxy-server.conf-sample
	echocolor "Done install swift proxy"
}

swift_proxy_config () {
	echocolor "Config swift proxy in controller node"

	proxy_serverfile=/etc/swift/proxy-server.conf
	proxy_serverfilebak=/etc/swift/proxy-server.conf.bak
	cp $proxy_serverfile $proxy_serverfilebak


	ops_add $proxy_serverfile DEFAULT bind_port 8080
	ops_add $proxy_serverfile DEFAULT user swift
	ops_add $proxy_serverfile DEFAULT swift_dir /etc/swift
	ops_add $proxy_serverfile DEFAULT bind_ip 0.0.0.0

	ops_add $proxy_serverfile "pipeline:main" pipeline "catch_errors gatekeeper healthcheck proxy-logging cache container_sync bulk ratelimit container-quotas account-quotas slo dlo versioned_writes proxy-server proxy-logging listing_formats copy symlink authtoken keystoneauth"

	ops_add $proxy_serverfile "app:proxy-server" account_autocreate True
	
	ops_add $proxy_serverfile "filter:keystoneauth" operator_roles "admin,user"

	ops_add $proxy_serverfile "filter:authtoken" paste.filter_factory "keystonemiddleware.auth_token:filter_factory"

	ops_add $proxy_serverfile "filter:authtoken" www_authenticate_uri http://$HOST_CTL:5000
	ops_add $proxy_serverfile "filter:authtoken" auth_url http://$HOST_CTL:5000
	ops_add $proxy_serverfile "filter:authtoken" memcached_servers $HOST_CTL:11211
	ops_add $proxy_serverfile "filter:authtoken" auth_type password
	ops_add $proxy_serverfile "filter:authtoken" project_domain_name default
	ops_add $proxy_serverfile "filter:authtoken" user_domain_name default
	ops_add $proxy_serverfile "filter:authtoken" project_name service
	ops_add $proxy_serverfile "filter:authtoken" username swift
	ops_add $proxy_serverfile "filter:authtoken" password openstack
	ops_add $proxy_serverfile "filter:authtoken" delay_auth_decision True

	ops_add $proxy_serverfile filter:cache use "egg:swift#memcache"
	ops_add $proxy_serverfile filter:cache memcache_servers $HOST_CTL:11211


	echocolor "Done config swift proxy in controller node"
}


# swift_pre_install

swift_proxy_install

swift_proxy_config

# Install swift in storage node
source /home/openstack/Stein/str-07-swift-install.sh

# Install swift in controller node
source /home/openstack/Stein/ctl-07-swift-ring.sh

# Verify install swift service
verify_swift_install (){
	swift-init all start
	echocolor "Verify install swift service"
	sleep 3
	source /root/admin-openrc
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