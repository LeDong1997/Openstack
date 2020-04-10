#!/bin/bash
#Custom by Le Nam

source functions.sh
source info_config.sh

swift_preinstall(){
	echocolor "Check hardware install swift"
	sleep 3

	lsblk
	apt-get install xfsprogs rsync -y

	echocolor "Format XFS"
	sleep 3
	mkfs.xfs /dev/sdc
	mkfs.xfs /dev/sdd

	mkdir -p /srv/node/sdc
	mkdir -p /srv/node/sdd

	fstabfile=/etc/fstab
	# echo "/dev/sdc /srv/node/sdc xfs noatime,nodiratime,nobarrier,logbufs=8 0 2" >> $fstabfile
	# echo "/dev/sdd /srv/node/sdd xfs noatime,nodiratime,nobarrier,logbufs=8 0 2" >> $fstabfile

	mount /srv/node/sdc
	mount /srv/node/sdd

	echocolor "Create rsyncd.conf"
	rsyncdfile=/etc/rsyncd.conf

	cat << EOF > $rsyncdfile
uid = swift		
gid = swift		
log file = /var/log/rsyncd.log		
pid file = /var/run/rsyncd.pid		
address = $CTL_MGNT_IP		
		
[account]		
max connections = 2		
path = /srv/node/		
read only = False		
lock file = /var/lock/account.lock		
		
[container]		
max connections = 2		
path = /srv/node/		
read only = False		
lock file = /var/lock/container.lock		
		
[object]		
max connections = 2		
path = /srv/node/		
read only = False		
lock file = /var/lock/object.lock		
EOF

	sed -i 's/RSYNC_ENABLE=false/RSYNC_ENABLE=true/g' "/etc/default/rsync"
	service rsync start
	echocolor "Done pre install swift in storage node"
}

# Install swift
swift_install(){
	echocolor "Install swift"
	sleep 3

	apt-get install swift swift-account swift-container swift-object -y
	curl -o /etc/swift/account-server.conf https://opendev.org/openstack/swift/raw/branch/stable/stein/etc/account-server.conf-sample
	curl -o /etc/swift/container-server.conf https://opendev.org/openstack/swift/raw/branch/stable/stein/etc/container-server.conf-sample
	curl -o /etc/swift/object-server.conf https://opendev.org/openstack/swift/raw/branch/stable/stein/etc/object-server.conf-sample

	echocolor "Edit account-server.conf"
	account_serverfile=/etc/swift/account-server.conf
	account_serverfilebak=/etc/swift/account-server.conf.bak
	cp $account_serverfile $account_serverfilebak

	ops_add $account_serverfile DEFAULT bind_ip 0.0.0.0
	ops_add $account_serverfile DEFAULT bind_port 6202
	ops_add $account_serverfile DEFAULT user swift
	ops_add $account_serverfile DEFAULT swift_dir /etc/swift
	ops_add $account_serverfile DEFAULT devices /srv/node
	ops_add $account_serverfile DEFAULT mount_check true

	ops_add $account_serverfile filter:recon recon_cache_path /var/cache/swift

	echocolor "Edit container-server.conf"
	container_serverfile=/etc/swift/container-server.conf
	container_serverfilebak=/etc/swift/container-server.conf.bak
	cp $container_serverfile $container_serverfilebak

	ops_add $container_serverfile DEFAULT bind_ip 0.0.0.0
	ops_add $container_serverfile DEFAULT bind_port 6201
	ops_add $container_serverfile DEFAULT user swift
	ops_add $container_serverfile DEFAULT swift_dir /etc/swift
	ops_add $container_serverfile DEFAULT devices /srv/node
	ops_add $container_serverfile DEFAULT mount_check true

	ops_add $container_serverfile "filter:recon" recon_cache_path /var/cache/swift

	echocolor "Edit object-server.conf"
	object_serverfile=/etc/swift/object-server.conf
	object_serverfilebak=/etc/swift/object-server.conf.bak
	cp $object_serverfile $object_serverfilebak

	ops_add $object_serverfile DEFAULT bind_ip 0.0.0.0
	ops_add $object_serverfile DEFAULT bind_port 6200
	ops_add $object_serverfile DEFAULT user swift
	ops_add $object_serverfile DEFAULT swift_dir /etc/swift
	ops_add $object_serverfile DEFAULT devices /srv/node
	ops_add $object_serverfile DEFAULT mount_check true

	ops_add $object-serverfile "filter:recon" recon_cache_path /var/cache/swift
	ops_add $object-serverfile "filter:recon" recon_lock_path /var/lock

	chown -R swift:swift /srv/node/
	mkdir -p /var/cache/swift
	chown -R root:swift /var/cache/swift
	chmod -R 775 /var/cache/swift
}

#######################
###Execute functions###
#######################

# Function preinstall swift
swift_preinstall

# Function install swift in storage node
swift_install
