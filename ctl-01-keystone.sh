#!/bin/bash
#Custom by Le Nam

source functions.sh
source info_config.sh

# Function create database for Keystone service
keystone_create_db () {
	echocolor "Create database for Keystone service"
	sleep 3

	cat << EOF | mysql
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
IDENTIFIED BY '$KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
IDENTIFIED BY '$KEYSTONE_DBPASS';
FLUSH PRIVILEGES;
EOF
	echocolor "Done create database for keystone service"
}

# Function install components of Keystone
keystone_install () {
	echocolor "Install and configure components of Keystone"
	sleep 3
	apt-get install -y keystone python-openstackclient apache2 libapache2-mod-wsgi-py3 python-oauth2client crudini
	echocolor "Done install keystone"
}

# Function configure components of Keystone
keystone_config () {
	echocolor "Create file backup keystone"
	keystone_file=/etc/keystone/keystone.conf
	keystone_bak_file=/etc/keystone/keystone.conf.bak
	cp $keystone_file $keystone_bak_file
	egrep -v "^#|^$" $keystone_bak_file > $keystone_file

	ops_add $keystone_file database connection mysql+pymysql://keystone:$KEYSTONE_DBPASS@$HOST_CTL/keystone
	ops_add $keystone_file token provider fernet
	ops_add $keystone_file cache memcache_servers $HOST_CTL:11211
	echocolor "Done config keystone"
}

# Function populate the Identity service database
keystone_populate_db () {
	echocolor "Start create database for keystone"
	su -s /bin/sh -c "keystone-manage db_sync" keystone
	echocolor "Done create database for keystone"
}

# Function initialize Fernet key repositories
keystone_initialize_key () {
	echocolor "Initialize Fernet key repositories"
	keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
	keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
	echocolor "Done initialize Fernet key repositories"
}
	
# Function bootstrap the Identity service
keystone_bootstrap () {
	echocolor "Install bootstrap for keystone"
	keystone-manage bootstrap --bootstrap-password $ADMIN_PASS \
	  --bootstrap-admin-url http://$HOST_CTL:5000/v3/ \
	  --bootstrap-internal-url http://$HOST_CTL:5000/v3/ \
	  --bootstrap-public-url http://$HOST_CTL:5000/v3/ \
	  --bootstrap-region-id RegionOne
	echocolor "Done install bootstrap for keystone"
}
	
# Function configure the Apache HTTP server
keystone_config_apache () {
	echocolor "Configure the Apache HTTP Server"
	sleep 3
	apache_file=/etc/apache2/apache2.conf

	echo "ServerName $HOST_CTL" >> $apache_file
	echocolor "Done configure the Apache HTTP Server"
}

# Function finalize the installation
keystone_finalize_install () {
	echocolor "Finalize the installation. Restart apache server"
	sleep 3
	service apache2 restart
}

# Function create domain, projects, users and roles
keystone_create_domain_project_user_role () {
	export OS_PROJECT_DOMAIN_NAME=Default
	export OS_USER_DOMAIN_NAME=Default
	export OS_PROJECT_NAME=admin
	export OS_USERNAME=admin
	export OS_PASSWORD=$ADMIN_PASS
	export OS_AUTH_URL=http://$HOST_CTL:5000/v3
	export OS_IDENTITY_API_VERSION=3
	export OS_IMAGE_API_VERSION=2

	echocolor "Create domain, projects, users and roles"
	sleep 3

	openstack project create --domain default --description "Service Project" service	  
	openstack project create --domain default --description "Demo Project" demo
	openstack user create --domain default --password $DEMO_PASS demo
	openstack role create user
	openstack role add --project demo --user demo user
	echocolor "Done create domain, projects, users and roles"
}

# Function create OpenStack client environment scripts
keystone_create_opsclient_scripts () {
	echocolor "Create OpenStack client environment scripts" 
	sleep 3

	echocolor "Create admin environment script"
	sleep 3
	cat << EOF > /root/admin-openrc
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://$HOST_CTL:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

	chmod +x /root/admin-openrc

	echocolor "Create demo environment script"
	sleep 3
	cat << EOF > /root/demo-openrc
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=$DEMO_PASS
export OS_AUTH_URL=http://$HOST_CTL:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

	chmod +x /root/demo-openrc
	echocolor "Done create environment script"
}

# Function verifying keystone
keystone_verify () {
	echocolor "Verifying keystone using admin environment script"
	sleep 3
	source /root/admin-openrc
	openstack token issue

	echocolor "Verifying keystone using demo environment script"
	sleep 3
	source /root/demo-openrc
	openstack token issue
	echocolor "Done verifying keystone service"
}

#######################
###Execute functions###
#######################

# Create database for Keystone
keystone_create_db

# Install components of Keystone
keystone_install

# Configure components of Keystone
keystone_config

# Populate the Identity service database
keystone_populate_db

# Initialize Fernet key repositories
keystone_initialize_key

# Bootstrap the Identity service
keystone_bootstrap

# Configure the Apache HTTP server
keystone_config_apache

# Finalize the installation
keystone_finalize_install

# Create domain, projects, users and roles
keystone_create_domain_project_user_role

# Create OpenStack client environment scripts
keystone_create_opsclient_scripts

# Verifying keystone
keystone_verify
