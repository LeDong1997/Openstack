#!/bin/bash
#Custom by Le Nam

source functions.sh
source info_config.sh

# Function create database for Nova
nova_create_db () {
	echocolor "Create database for Nova Service"
	sleep 3

	cat << EOF | mysql
CREATE DATABASE nova_api;
CREATE DATABASE nova;
CREATE DATABASE nova_cell0;
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS';

GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS';

GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS';

FLUSH PRIVILEGES;
EOF
	echocolor "Done create database for Nova service"
}

# Function create infomation for Compute service
nova_create_info () {
	echocolor "Set environment variable for user admin"
	source /root/admin-openrc
	echocolor "Create infomation for Compute service"
	sleep 3

	## Create info for nova user
	echocolor "Create info for nova user"
	sleep 3

	openstack user create --domain default --password $NOVA_PASS nova
	openstack role add --project service --user nova admin
	openstack service create --name nova --description "OpenStack Compute" compute
	openstack endpoint create --region RegionOne compute public http://$HOST_CTL:8774/v2.1
	openstack endpoint create --region RegionOne compute internal http://$HOST_CTL:8774/v2.1
	openstack endpoint create --region RegionOne compute admin http://$HOST_CTL:8774/v2.1

	## Create info for placement user
	echocolor "Create info for placement user"
	sleep 3

	openstack user create --domain default --password $PLACEMENT_PASS placement
	openstack role add --project service --user placement admin
	openstack service create --name placement --description "Placement API" placement
	openstack endpoint create --region RegionOne placement public http://$HOST_CTL:8778
	openstack endpoint create --region RegionOne placement internal http://$HOST_CTL:8778
	openstack endpoint create --region RegionOne placement admin http://$HOST_CTL:8778
	echocolor "Done create infomation for Nova service"
}

# Function install components of Nova
nova_install () {
	echocolor "Install nova package"
	sleep 3
	apt-get install -y nova-api nova-conductor nova-consoleauth \
	  nova-novncproxy nova-scheduler nova-placement-api python3-novaclient
	echocolor "Done install nova package"
}

# Function config /etc/nova/nova.conf file
nova_config () {
	echocolor "Start config nova service"
	nova_file=/etc/nova/nova.conf
	nova_bak_file=/etc/nova/nova.conf.bak
	cp $nova_file $nova_bak_file
	egrep -v "^$|^#" $nova_bak_file > $nova_file

	ops_del $nova_file api_database connection
	ops_add $nova_file api_database connection mysql+pymysql://nova:$NOVA_DBPASS@$HOST_CTL/nova_api
	
	ops_add $nova_file database connection mysql+pymysql://nova:$NOVA_DBPASS@$HOST_CTL/nova

	ops_add $nova_file DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$HOST_CTL
	
	ops_add $nova_file api auth_strategy keystone

	ops_add $nova_file keystone_authtoken www_authenticate_uri http://$HOST_CTL:5000
	ops_add $nova_file keystone_authtoken auth_url http://$HOST_CTL:5000
	ops_add $nova_file keystone_authtoken memcached_servers $HOST_CTL:11211
	ops_add $nova_file keystone_authtoken auth_type password
	ops_add $nova_file keystone_authtoken project_domain_name default
	ops_add $nova_file keystone_authtoken user_domain_name default
	ops_add $nova_file keystone_authtoken project_name service
	ops_add $nova_file keystone_authtoken username nova
	ops_add $nova_file keystone_authtoken password $NOVA_PASS

	ops_add $nova_file DEFAULT my_ip $CTL_MGNT_IP

	ops_add $nova_file DEFAULT use_neutron True
	ops_add $nova_file DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

	ops_add $nova_file vnc enabled true
	ops_add $nova_file vnc server_listen \$my_ip
	ops_add $nova_file vnc server_proxyclient_address \$my_ip

	ops_add $nova_file glance api_servers http://$HOST_CTL:9292

	ops_add $nova_file oslo_concurrency lock_path /var/lib/nova/tmp

	ops_del $nova_file DEFAULT log_dir

	ops_del $nova_file placement os_region_name
	ops_add $nova_file placement os_region_name RegionOne
	ops_add $nova_file placement project_domain_name Default
	ops_add $nova_file placement project_name service
	ops_add $nova_file placement auth_type password
	ops_add $nova_file placement user_domain_name Default
	ops_add $nova_file placement auth_url http://$HOST_CTL:5000
	ops_add $nova_file placement username placement
	ops_add $nova_file placement password $PLACEMENT_PASS

	echocolor "Done config nova service"
}

# Function populate the nova-api database
nova_populate_nova-api_db () {
	echocolor "Populate the nova-api database"
	sleep 3
	su -s /bin/sh -c "nova-manage api_db sync" nova
	echocolor "Done populate the nova-api database"
}

# Function register the cell0 database
nova_register_cell0 () {
	echocolor "Register the cell0 database"
	sleep 3
	su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
	echocolor "Done register the cell0 database"
}

# Function create the cell1 cell
nova_create_cell1 () {
	echocolor "Create the cell1 cell"
	sleep 3
	su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
	echocolor "Done create the cell1 cell"
}

# Function populate the nova database
nova_populate_nova_db () {
	echocolor "Populate the nova database"
	sleep 3
	su -s /bin/sh -c "nova-manage db sync" nova
	echocolor "Done populate the nova database"
}

# Function verify nova cell0 and cell1 are registered correctly
nova_verify_cell () {
	echocolor "Verify nova cell0 and cell1 are registered correctly"
	sleep 3
	su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova
	echocolor "Done verity register nova cell0/cell1"
}

# Function restart installation
nova_restart () {
	echocolor "Finalize installation"
	sleep 3

	service nova-api restart
	service nova-consoleauth restart
	service nova-scheduler restart
	service nova-conductor restart
	service nova-novncproxy restart
	service apache2 restart
	source /root/admin-openrc
	openstack compute service list
	echocolor "Done finalize installation nova service"
}

#######################
###Execute functions###
#######################

# Create database for Nova
nova_create_db

# Create infomation for Compute service
nova_create_info

# Install components of Nova
nova_install

# Config /etc/nova/nova.conf file
nova_config

# Populate the nova-api database
nova_populate_nova-api_db

# Register the cell0 database
nova_register_cell0

# Create the cell1 cell
nova_create_cell1

# Populate the nova database
nova_populate_nova_db

# Verify nova cell0 and cell1 are registered correctly
nova_verify_cell

# Restart installation
nova_restart