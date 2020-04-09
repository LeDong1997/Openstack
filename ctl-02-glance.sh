#!/bin/bash
#Custom by Le Nam

source functions.sh
source info_config.sh

# Function create database for Glance
glance_create_db () {
	echocolor "Create database for Glance service"
	sleep 3

	cat << EOF | mysql
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$GLANCE_DBPASS';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$GLANCE_DBPASS';
FLUSH PRIVILEGES;
EOF
	echocolor "Done create database for Glance service"
}

# Function create the Glance service credentials
glance_create_service () {
	echocolor "Set variable environment for admin user"
	sleep 3
	source /root/admin-openrc

	echocolor "Create the service credentials"
	sleep 3

	openstack user create --domain default --password $GLANCE_PASS glance
	openstack role add --project service --user glance admin
	openstack service create --name glance --description "OpenStack Image" image
	openstack endpoint create --region RegionOne image public http://$HOST_CTL:9292
	openstack endpoint create --region RegionOne image internal http://$HOST_CTL:9292
	openstack endpoint create --region RegionOne image admin http://$HOST_CTL:9292
	echocolor "Done create the service credentials for glance"
}

# Function install components of Glance
glance_install () {
	echocolor "Install glance service"
	sleep 3

	apt-get update
	apt-get install glance -y
	echocolor "Done install for glance service"
}

# Function config /etc/glance/glance-api.conf file
glance_config_api () {
	echocolor "Config Glance API"
	glance_api_file=/etc/glance/glance-api.conf
	glance_api_bak_file=/etc/glance/glance-api.conf.bak
	cp $glance_api_file $glance_api_bak_file
	egrep -v "^#|^$"  $glance_api_bak_file > $glance_api_file

	ops_add $glance_api_file database connection mysql+pymysql://glance:$GLANCE_DBPASS@$HOST_CTL/glance
	
	ops_add $glance_api_file keystone_authtoken auth_uri http://$HOST_CTL:5000	  
	ops_add $glance_api_file keystone_authtoken auth_url http://$HOST_CTL:5000
	ops_add $glance_api_file keystone_authtoken memcached_servers $HOST_CTL:11211	  
	ops_add $glance_api_file keystone_authtoken auth_type password	  
	ops_add $glance_api_file keystone_authtoken project_domain_name Default
	ops_add $glance_api_file keystone_authtoken user_domain_name Default
	ops_add $glance_api_file keystone_authtoken project_name service		
	ops_add $glance_api_file keystone_authtoken username glance
	ops_add $glance_api_file keystone_authtoken password $GLANCE_PASS
	
	ops_add $glance_api_file paste_deploy flavor keystone	
	
	ops_add $glance_api_file glance_store stores file,http		
	ops_add $glance_api_file glance_store default_store file		
	ops_add $glance_api_file glance_store filesystem_store_datadir /var/lib/glance/images/
	
	ops_add $glance_api_file DEFAULT bind_hosts 0.0.0.0
	echocolor "Done config glance api"
}

# Function populate the Image service database
glance_populate_db () {
	echocolor "Populate the Image service database"
	sleep 3
	su -s /bin/sh -c "glance-manage db_sync" glance
	echocolor "Done populate the image service"
}

# Function restart the Image services
glance_restart () {
	echocolor "Restart the Image services"
	sleep 3

	service glance-api restart 
	echocolor "Done restart the image service"
}

# Function upload image to Glance
glance_upload_image () {
	echocolor "Upload new image to Glance"
	sleep 3
	source /root/admin-openrc
	apt-get install wget -y
	wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img


	openstack image create "cirros-0.4.0" \
	  --file cirros-0.4.0-x86_64-disk.img \
	  --disk-format qcow2 --container-format bare \
	  --public
	  
	openstack image list
	echocolor "Done upload new image to glance service"
}

#######################
###Execute functions###
#######################

# Create database for Glance
glance_create_db

# Create the Glance service credentials
glance_create_service

# Install components of Glance
glance_install

# Config /etc/glance/glance-api.conf file
glance_config_api

# Populate the Image service database 
glance_populate_db

# Restart the Image services
glance_restart 
  
# Upload image to Glance
glance_upload_image
