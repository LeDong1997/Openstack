#!/bin/bash
#Custom by Le Nam

source functions.sh
source info_config.sh

# Function create database for Cinder
cinder_create_db () {
	echocolor "Create database for Cinder"
	sleep 3

	cat << EOF | mysql
CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '$CINDER_DBPASS';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '$CINDER_DBPASS';
FLUSH PRIVILEGES;
EOF
	echocolor "Done Create database for Cinder"
}

# Function create the cinder service credentials
cinder_create_info () {
	echocolor "Set environment variable for admin user"
	source /root/admin-openrc
	echocolor "Create the cinder service credentials"
	sleep 3

	openstack user create --domain default --password $CINDER_PASS cinder
	openstack role add --project service --user cinder admin
	openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
	openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3

	openstack endpoint create --region RegionOne volumev2 public http://controller:8776/v2/%\(project_id\)s
	openstack endpoint create --region RegionOne volumev2 internal http://controller:8776/v2/%\(project_id\)s
	openstack endpoint create --region RegionOne volumev2 admin http://controller:8776/v2/%\(project_id\)s

	openstack endpoint create --region RegionOne volumev3 public http://controller:8776/v3/%\(project_id\)s
	openstack endpoint create --region RegionOne volumev3 internal http://controller:8776/v3/%\(project_id\)s
	openstack endpoint create --region RegionOne volumev3 admin http://controller:8776/v3/%\(project_id\)s
	echocolor "Done Create the cinder service credentials"
}

# Function install the components
cinder_install () {
	echocolor "Install the components"
	sleep 3

	apt install cinder-api cinder-scheduler -y
	echocolor "Done install the components cinder"
}

# Function configure the server component
cinder_config_server_component () { 
	echocolor "Configure the server component"
	sleep 3

	# cinderfile=/etc/cinder/cinder.conf
	# cinderfilebak=/etc/cinder/cinder.conf.bak

	# cp $cinderfile $cinderfilebak
	# egrep -v "^$|^#" $cinderfilebak > $cinderfile

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

	ops_add $cinderfile DEFAULT my_ip $HOST_CTL

	ops_add $cinderfile oslo_concurrency lock_path /var/lib/cinder/tmp
	echocolor "Done configure the server component cinder"
}

# Function populate the database
cinder_populate_db () {
	echocolor "Populate the database for cinder service"
	sleep 3
	su -s /bin/sh -c "cinder-manage db sync" cinder
	echocolor "Done populate the database for cinder service"
}

# Configure Compute to use Block Storage
cinder_config_compute (){
	echocolor "Configure compute to use Block storage"
	sleep 3

	novafile=/etc/nova/nova.conf
	ops_add $novafile cinder os_region_name RegionOne
	echocolor "Done configure compute to use Block storage"
}

# Restart cinder service
cinder_restart (){
	echocolor "Restart cinder service in controller node"
	service nova-api restart
	service cinder-scheduler restart
	service apache2 restart
	echocolor "Done restart cinder service in controller node"
}

#######################
###Execute functions###
#######################

# Function create database for Cinder
cinder_create_db

# Function create the cinder service credentials
cinder_create_info

# Function install the components
cinder_install

# Function configure the server component
cinder_config_server_component

# Function populate the database
cinder_populate_db

# Configure Compute to use Block Storage
cinder_config_compute

# Restart cinder service
cinder_restart
