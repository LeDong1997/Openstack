#!/bin/bash
#Custom by Le Nam

source functions.sh

# Function create new user
add_user (){
	username="openstack"
	sudo useradd -d /home/$username -s /bin/bash -m $username -G sudo 
	sudo passwd $username
}

#######################
###Execute functions###
#######################

# Create new user in Controller/Compute/Storage Node
echocolor "Create new user"
sleep 3

# Create new user
add_user
