#!/bin/bash
#Custom by Le Nam

source functions.sh
source info_config.sh


# Function verify connect network
connect_network_verify (){
	echocolor "Test network connection"
	ping -c 3 8.8.8.8
	ping -c 3 controller
	ping -c 3 compute
	ping -c 3 storage
	echocolor "Done test network connection"
}

# Function create database for Neutron
neutron_create_db () {
	echocolor "Create database for Neutron service"
	sleep 3

	cat << EOF | mysql
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$NEUTRON_DBPASS';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$NEUTRON_DBPASS';
FLUSH PRIVILEGES;
EOF
	echocolor "Done create database for neutron service"
}

# Function create the neutron service credentials
neutron_create_info () {
	echocolor "Set environment variable for admin user"
	source /root/admin-openrc
	echocolor "Create the neutron service credentials"
	sleep 3

	openstack user create --domain default --password $NEUTRON_PASS neutron
	openstack role add --project service --user neutron admin
	openstack service create --name neutron --description "OpenStack Networking" network
	openstack endpoint create --region RegionOne network public http://$HOST_CTL:9696
	openstack endpoint create --region RegionOne network internal http://$HOST_CTL:9696
	openstack endpoint create --region RegionOne network admin http://$HOST_CTL:9696
	echocolor "Done create infomation for neutron service"
}

# Function install the components
neutron_install () {
	echocolor "Install the components"
	sleep 3

	apt install neutron-server neutron-plugin-ml2 \
	  neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent \
	  neutron-metadata-agent python3-neutronclient -y
	echocolor "Done install the components for neutron"
}

# Function configure the server component
neutron_config_server_component () { 
	echocolor "Configure the server component"
	sleep 3
	neutronfile=/etc/neutron/neutron.conf
	neutronfilebak=/etc/neutron/neutron.conf.bak
	cp $neutronfile $neutronfilebak
	egrep -v "^$|^#" $neutronfilebak > $neutronfile

	ops_del $neutronfile database connection 
	ops_add $neutronfile database connection mysql+pymysql://neutron:$NEUTRON_DBPASS@$HOST_CTL/neutron
	
	ops_add $neutronfile DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$HOST_CTL
	
	ops_del $neutronfile DEFAULT core_plugin
	ops_add $neutronfile DEFAULT core_plugin ml2
	ops_add $neutronfile DEFAULT service_plugins router
	ops_add $neutronfile DEFAULT allow_overlapping_ips true


	ops_add $neutronfile DEFAULT auth_strategy keystone
	ops_add $neutronfile keystone_authtoken auth_uri http://$HOST_CTL:5000
	ops_add $neutronfile keystone_authtoken auth_url http://$HOST_CTL:5000
	ops_add $neutronfile keystone_authtoken memcached_servers $HOST_CTL:11211
	ops_add $neutronfile keystone_authtoken auth_type password
	ops_add $neutronfile keystone_authtoken project_domain_name default
	ops_add $neutronfile keystone_authtoken user_domain_name default
	ops_add $neutronfile keystone_authtoken project_name service
	ops_add $neutronfile keystone_authtoken username neutron
	ops_add $neutronfile keystone_authtoken password $NEUTRON_PASS

	ops_add $neutronfile DEFAULT notify_nova_on_port_status_changes true
	ops_add $neutronfile DEFAULT notify_nova_on_port_data_changes true

	ops_add $neutronfile nova auth_url http://$HOST_CTL:5000
	ops_add $neutronfile nova auth_type password
	ops_add $neutronfile nova project_domain_name default
	ops_add $neutronfile nova user_domain_name default
	ops_add $neutronfile nova region_name RegionOne
	ops_add $neutronfile nova project_name service
	ops_add $neutronfile nova username nova
	ops_add $neutronfile nova password $NOVA_PASS

	ops_add $neutronfile oslo_concurrency lock_path /var/lib/neutron/tmp

	ops_add $neutronfile DEFAULT dhcp_agent_notification true
	ops_add $neutronfile agent root_helper "sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf"
	echocolor "Done config component for neutron service"
}

# Function configure the Modular Layer 2 (ML2) plug-in
neutron_config_ml2 () {
	echocolor "Configure the Modular Layer 2 (ML2) plug-in"
	sleep 3
	ml2file=/etc/neutron/plugins/ml2/ml2_conf.ini
	ml2filebak=/etc/neutron/plugins/ml2/ml2_conf.ini.bak
	cp $ml2file $ml2filebak
	egrep -v "^$|^#" $ml2filebak > $ml2file

	ops_add $ml2file ml2 type_drivers flat,vlan,vxlan

	ops_add $ml2file ml2 tenant_network_types vxlan

	ops_add $ml2file ml2 mechanism_drivers linuxbridge,l2population

	ops_add $ml2file ml2 extension_drivers port_security

	ops_add $ml2file ml2_type_flat flat_networks provider

	ops_add $ml2file ml2_type_vxlan vni_ranges 1:1000

	ops_add $ml2file securitygroup enable_ipset true
	echocolor "done Configure the Modular Layer 2 (ML2) plug-in"
}

# Function configure the Linux bridge agent
neutron_config_linuxbridge () {
	echocolor "Configure the Linux Bridge agent"
	sleep 3
	# ovsfile=/etc/neutron/plugins/ml2/openvswitch_agent.ini
	# ovsfilebak=/etc/neutron/plugins/ml2/openvswitch_agent.ini.bak
	# cp $ovsfile $ovsfilebak
	# egrep -v "^$|^#" $ovsfilebak > $ovsfile

	linuxbridgefile=/etc/neutron/plugins/ml2/linuxbridge_agent.ini
	linuxbridgefilebak=/etc/neutron/plugins/ml2/linuxbridge_agent.ini.bak
	cp $linuxbridgefile $linuxbridgefilebak
	egrep -v "^$|^#" $linuxbridgefilebak > $linuxbridgefile

	#ops_add $ovsfile agent tunnel_types vxlan,gre
	#ops_add $ovsfile agent l2_population True
	#ops_add $ovsfile agent extensions qos
	#ops_add $ovsfile ovs bridge_mappings provider:br-provider
	#ops_add $ovsfile ovs local_ip $CTL_MGNT_IP
	#ops_add $ovsfile securitygroup firewall_driver openvswitch

	ops_add $linuxbridgefile linux_bridge physical_interface_mappings provider:$CTL_MAP_IF
	
	ops_add $linuxbridgefile vxlan enable_vxlan true
	ops_add $linuxbridgefile vxlan local_ip $CTL_MGNT_IP
	ops_add $linuxbridgefile vxlan l2_population true

	ops_add $linuxbridgefile securitygroup enable_security_group true
	ops_add $linuxbridgefile securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
	echocolor "Done configure the Linux Bridge agent"
}

# Function configure the L3 agent
neutron_config_l3 () {
	echocolor "Configure the L3 agent"
	l3file=/etc/neutron/l3_agent.ini
	l3filebak=/etc/neutron/l3_agent.ini.bak
	cp $l3file $l3filebak
	egrep -v "^$|^#" $l3filebak > $l3file

	ops_add $l3file DEFAULT interface_driver linuxbridge
	echocolor "Done configure the L3 agent"
}

# Function configure the DHCP agent
neutron_config_dhcp () {
	echocolor "Configure the DHCP agent"
	sleep 3
	dhcpfile=/etc/neutron/dhcp_agent.ini
	dhcpfilebak=/etc/neutron/dhcp_agent.ini.bak
	cp $dhcpfile $dhcpfilebak
	egrep -v "^$|^#" $dhcpfilebak > $dhcpfile

	#ops_add $dhcpfile DEFAULT interface_driver openvswitch
	#ops_add $dhcpfile DEFAULT enable_isolated_metadata true
	#ops_add $dhcpfile DEFAULT force_metadata True

	ops_add $dhcpfile DEFAULT interface_driver linuxbridge
	ops_add $dhcpfile DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
	ops_add $dhcpfile DEFAULT enable_isolated_metadata true
	echocolor "Done configure the DHCP agent"
}

# Function configure things relation
# Khong su dung
neutron_config_relation () {
	ovs-vsctl add-br br-provider
	ovs-vsctl add-port br-provider $CTL_EXT_IF
	ip a flush $CTL_EXT_IF
	ifconfig br-provider $CTL_EXT_IP netmask $CTL_EXT_NETMASK
	ip link set br-provider up
	ip r add default via $GATEWAY_EXT_IP
	echo "nameserver 8.8.8.8" > /etc/resolv.conf

	cat << EOF > /etc/network/interfaces
# loopback network interface
auto lo
iface lo inet loopback

# external network interface
# auto $CTL_EXT_IF
# iface $CTL_EXT_IF inet static
# address $CTL_EXT_IP
# netmask $CTL_EXT_NETMASK
# gateway $GATEWAY_EXT_IP
#dns-nameservers 8.8.8.8

auto br-provider
allow-ovs br-provider
iface br-provider inet static
    address $CTL_EXT_IP
    netmask $CTL_EXT_NETMASK
    gateway $GATEWAY_EXT_IP
    dns-nameservers 8.8.8.8
    ovs_type OVSBridge
    ovs_ports $CTL_EXT_IF

allow-br-provider $CTL_EXT_IF
iface $CTL_EXT_IF inet manual
    ovs_bridge br-provider
    ovs_type OVSPort

# internal network interface
auto $CTL_MGNT_IF
iface $CTL_MGNT_IF inet static
address $CTL_MGNT_IP
netmask $CTL_MGNT_NETMASK
EOF
}

# Function configure the metadata agent
neutron_config_metadata () {
	echocolor "Configure the metadata agent"
	sleep 3
	metadatafile=/etc/neutron/metadata_agent.ini
	metadatafilebak=/etc/neutron/metadata_agent.ini.bak
	cp $metadatafile $metadatafilebak
	egrep -v "^$|^#" $metadatafilebak > $metadatafile

	ops_add $metadatafile DEFAULT nova_metadata_host $HOST_CTL
	ops_add $metadatafile DEFAULT metadata_proxy_shared_secret $METADATA_SECRET

	ops_add $metadatafile cache memcache_servers $HOST_CTL:11211
	echocolor "Done configure the metadata agent"
}

# Function configure the Compute service to use the Networking service
neutron_config_compute_use_network () {
	echocolor "Configure the Compute service to use the Networking service"
	sleep 3
	novafile=/etc/nova/nova.conf

	ops_add $novafile neutron url http://$HOST_CTL:9696
	ops_add $novafile neutron auth_url http://$HOST_CTL:5000
	ops_add $novafile neutron auth_type password
	ops_add $novafile neutron project_domain_name default
	ops_add $novafile neutron user_domain_name default
	ops_add $novafile neutron region_name RegionOne
	ops_add $novafile neutron project_name service
	ops_add $novafile neutron username neutron
	ops_add $novafile neutron password $NEUTRON_PASS
	ops_add $novafile neutron service_metadata_proxy true
	ops_add $novafile neutron metadata_proxy_shared_secret $METADATA_SECRET
	echocolor "Done configure the Compute service to use the Networking service"
}

# Function populate the database
neutron_populate_db () {
	echocolor "Populate the database"
	sleep 3
	su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
	  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
	echocolor "Done populate the database"
}

# Function restart installation
neutron_restart () {
	echocolor "Restart neutron service"
	service nova-api restart
	service neutron-server restart
	#service neutron-openvswitch-agent restart
	service neutron-linuxbridge-agent restart
	service neutron-dhcp-agent restart
	service neutron-metadata-agent restart
	service neutron-l3-agent restart
	echocolor "Done restart neutron service"
}

#######################
###Execute functions###
#######################

# Verify connect network
connect_network_verify

# Create database for Neutron
neutron_create_db

# Create the neutron service credentials
neutron_create_info

# Install the components
neutron_install

# Configure the server component
neutron_config_server_component

# Configure the Modular Layer 2 (ML2) plug-in
neutron_config_ml2

# Configure the Linux bridge agent
neutron_config_linuxbridge

# Configure the L3 agent
neutron_config_l3

# Configure the DHCP agent
neutron_config_dhcp

# Configure the metadata agent
neutron_config_metadata

# Configure the Compute service to use the Networking service
neutron_config_compute_use_network

# Populate the database
neutron_populate_db

# Function restart installation
neutron_restart