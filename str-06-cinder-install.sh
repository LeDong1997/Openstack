#!/bin/bash
#Custom by Le Nam

source functions.sh
source info_config.sh

# Function install
cinder_install (){
	apt-get update

	echocolor "Install Cinder in storage node"
	sleep 3
	apt install lvm2 thin-provisioning-tools crudini -y
	echocolor "Done Install Cinder in storage node"
}

# Create LVM physical volume
cinder_create_lvm (){
	echocolor "Create LVM physical volume"
	sleep 3
	pvcreate /dev/sdb
	vgcreate cinder-volumes /dev/sdb

	lvmfile=/etc/lvm/lvm.conf
	lvmfilebak=/etc/lvm/lvm.conf.bak
	cp $lvmfile $lvmfilebak
	egrep -v "^$|^#" $lvmfilebak > $lvmfile
	sed -i '130i\	filter = [ "a/sda/", "a/sdb/", "r/.*/"]' $lvmfile
	#sed -r -i 's#(filter = )(\[ "a/\.\*/" \])#\1["a\/vdb\/", "r/\.\*\/"]#g' /etc/lvm/lvm.conf
    # fix filter cua lvm tren CentOS 7.4, chen vao dong 141 cua file /etc/lvm/lvm.conf sed -i '141i\ filter = [ "a/vdb/", "r/.*/"]' /etc/lvm/lvm.conf
    echocolor "Done create LVM physical volume"
}

# Install and configure components
cinder_install_component (){
	echocolor "Install cinder volume"
	sleep 3
	apt install cinder-volume -y
	echocolor "Done install cinder volume in storage node"
}

# Configure cinder volume
cinder_config (){
	echocolor "Configure cinder volume in storage"
	sleep 3
	cinderfile=/etc/cinder/cinder.conf
	cinderfilebak=/etc/cinder/cinder.conf.bak
	cp $cinderfile $cinderfilebak
	egrep -v "^$|^#" $cinderfilebak > $cinderfile
	ops_add $cinderfile database connection mysql+pymysql://cinder:$CINDER_DBPASS@$HOST_CTL/cinder
	
	ops_add $cinderfile DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$HOST_CTL
	
	ops_add $cinderfile DEFAULT auth_strategy keystone
	
	ops_add $cinderfile keystone_authtoken www_authenticate_uri http://$HOST_CTL:5000
	ops_add $cinderfile keystone_authtoken auth_url http://$HOST_CTL:5000
	ops_add $cinderfile keystone_authtoken memcached_servers $HOST_CTL:11211
	ops_add $cinderfile keystone_authtoken auth_type password
	ops_add $cinderfile keystone_authtoken project_domain_id default
	ops_add $cinderfile keystone_authtoken user_domain_id default
	ops_add $cinderfile keystone_authtoken project_name service
	ops_add $cinderfile keystone_authtoken username cinder
	ops_add $cinderfile keystone_authtoken password $CINDER_PASS
	
	ops_add $cinderfile DEFAULT my_ip $STR1_MGNT_IP
	
	ops_add $cinderfile lvm volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver
	ops_add $cinderfile lvm volume_group cinder-volumes
	ops_add $cinderfile lvm iscsi_protocol iscsi
	ops_add $cinderfile lvm iscsi_helper tgtadm
	
	ops_add $cinderfile DEFAULT enabled_backends lvm
	
	ops_add $cinderfile DEFAULT glance_api_servers http://$HOST_CTL:9292
	
	ops_add $cinderfile oslo_concurrency lock_path /var/lib/cinder/tmp
	echocolor "Done configure cinder volume in storage"
}

# Restart block storage volume service
cinder-volume_restart (){
	service tgt restart
	service cinder-volume restart
}

#######################
###Execute functions###
#######################

# Function install
cinder_install

# Create LVM physical volume
cinder_create_lvm

# Install and configure components
cinder_install_component

# Configure cinder volume
cinder_config

# Restart cinder-volume service
cinder-volume_restart
