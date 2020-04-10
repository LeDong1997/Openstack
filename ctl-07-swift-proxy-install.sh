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
	echocolor "Install swift proxy"
	apt-get install -y swift swift-proxy python3-swiftclient python3-keystonemiddleware python3-memcache python3-keystoneclient

	mkdir /etc/swift
	curl -o /etc/swift/proxy-server.conf https://opendev.org/openstack/swift/raw/branch/stable/stein/etc/proxy-server.conf-sample
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

	sed -i 's/pipeline = catch_errors gatekeeper healthcheck proxy-logging cache listing_formats container_sync bulk tempurl ratelimit tempauth copy container-quotas account-quotas slo dlo versioned_writes symlink proxy-logging proxy-server/\
pipeline = catch_errors gatekeeper healthcheck proxy-logging cache listing_formats container_sync bulk ratelimit authtoken keystoneauth copy container-quotas account-quotas slo dlo versioned_writes symlink proxy-logging proxy-server/g' $proxy_serverfile

	ops_add $proxy_serverfile "app:proxy-server" account_autocreate True
	
	ops_add $proxy_serverfile "filter:keystoneauth" use "egg:swift#keystoneauth"
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


swift_pre_install

swift_proxy_install

swift_proxy_config