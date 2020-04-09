#!/bin/bash
#Custom by Le Nam

# Define color of notification in screen
function echocolor {
    echo "#######################################################################"
    echo "$(tput setaf 2)##### $1 #####$(tput sgr0)"
    echo "#######################################################################"
}

# Function modify config file of OpenStack
## add() function 
function ops_add {
	crudini --set $1 $2 $3 $4
}
## Syntax
### ops_add PATH_FILE SECTION PARAMETER VAULE

## del() function
function ops_del {
	crudini --del $1 $2 $3
}
## Syntax
### ops_del PATH_FILE SECTION PARAMETER
