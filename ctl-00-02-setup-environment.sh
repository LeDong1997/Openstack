#!/bin/bash
#Custom by Le Nam

source functions.sh
source info_config.sh

# Function update and upgrade for CONTROLLER
update_upgrade () {
	echocolor "Update and upgrade package in controller node"
	sleep 3
	apt-get update && sudo apt-get upgrade -y
	echocolor "Done update and upgrade"
}

# Function install basic Linux Utilities
install_linux_package () {
	echocolor "Install basic Linux Utilities"
	sleep 3
	apt-get install -y vim glances curl
	echocolor "Done install basic Linux Utilities"
}

# Function install crudini package
install_crudini () {
	echocolor "Install crudini package"
	sleep 3
	apt-get install -y crudini
	echocolor "Done install crudini package"
}

# Function install and config NTP service
install_ntp () {
	echocolor "Set timezone Asia/Ho_Chi_Minh"
	timedatectl set-timezone Asia/Ho_Chi_Minh
	sleep 3

	echocolor "Install NTP Service"
	sleep 3

	apt-get install -y chrony
	ntp_file=/etc/chrony/chrony.conf
	ntp_bak_file=/etc/chrony/chrony.conf.bak

	# Backup config file
	cp ntp_file ntp_bak_file

	sed -i 's/pool 2.debian.pool.ntp.org offline iburst/ \
pool 2.debian.pool.ntp.org offline iburst \
server 0.asia.pool.ntp.org iburst \
server 1.asia.pool.ntp.org iburst/g' $ntp_file

	echo "allow $CIDR_MGNT" >> $ntp_file

	service chrony restart
	echocolor "Done install ntp service"
}

# Function install OpenStack packages
install_ops_packages () {
	echocolor "Install OpenStack Stein"
	sleep 3
	apt-get install -y software-properties-common
	add-apt-repository cloud-archive:stein -y
	apt-get update -y && sudo apt-get dist-upgrade -y

	apt-get install -y python3-openstackclient

	echocolor "Done install openstack stein"
}

# Function install mysql (Mariadb)
install_sql () {
	echocolor "Install MariaDB - SQL database"
	sleep 3

	# Add repository for Ubuntu Server 18.04 LTS
	add-apt-repository universe -y
	apt-get update

	# Install last version MarriaDB
	apt-get install -y software-properties-common
	apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 -y
	add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirror.lstn.net/mariadb/repo/10.4/ubuntu bionic main' -y
	apt-get update

	apt-get install -y mariadb-server python-pymysql

	sql_file=/etc/mysql/mariadb.conf.d/99-openstack.cnf
	touch $sql_file
	cat << EOF >$sql_file
[mysqld]
bind-address = $CTL_MGNT_IP
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF

	service mysql restart
	echocolor "Done install sql service"
}

# Function install message queue
install_message_queue () {
	echocolor "Install RabbitMQ - Message queue"
	sleep 3

	apt-get install -y rabbitmq-server
	rabbitmqctl add_user openstack $RABBIT_PASS
	rabbitmqctl set_permissions openstack ".*" ".*" ".*"
	echocolor "Done install RabbitMQ"
}

# Function install Memcached
install_memcached () {
	echocolor "Install Memcached"
	sleep 3

	apt-get install memcached python-memcache -y
	memcache_file=/etc/memcached.conf
	memcache_bak_file=/etc/memcached.conf.bak

	# Backup config file
	cp memcache_file memcache_bak_file

	sed -i 's|-l 127.0.0.1|'"-l $CTL_MGNT_IP"'|g' $memcache_file

	service memcached restart
	echocolor "Done install memcached"
} 

#######################
###Execute functions###
#######################

# Update and upgrade for controller
update_upgrade

# Install Linux Utilities
install_linux_package

# Install crudini
install_crudini

# Install and config NTP
install_ntp

# OpenStack packages (python-openstackclient)
install_ops_packages

# Install SQL database (Mariadb)
install_sql

# Install Message queue (rabbitmq)
install_message_queue

# Install Memcached
install_memcached
