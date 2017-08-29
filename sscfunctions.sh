#!/usr/bin/env bash
#
#########################  FUNCTIONS  #####################################

#####################  Set Security Posture  ##############################

function set_security_posture {

	COMPARTMENT=$1
	SECURITY_POSTURE=$2


	case $SECURITY_POSTURE in
		"whitelist-mode")
			echo
			echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			echo "                      SETTING SECURITY POSTURE TO WHITELIST MODE"
			ssc compartments set-security-posture --compartment-name $COMPARTMENT --whitelist-mode
			echo;sleep 1
			;;
		"firewall-mode")
			echo
			echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			echo "                      SETTING SECURITY POSTURE TO FIREWALL MODE"
			ssc compartments set-security-posture --compartment-name $COMPARTMENT --firewall-mode
			echo;sleep 1
			;;
		"observation-mode")
			echo
			echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			echo "                      SETTING SECURITY POSTURE TO OBSERVATION MODE"
			ssc compartments set-security-posture --compartment-name $COMPARTMENT --observation-mode
			echo;sleep 1
			;;
	esac
	if [ $? != 0 ]; then
		echo "  !!! FAILED TO SET SECURITY POSTURE !!!"; echo
		FAILED_WITH_ERRORS=1
	fi
}


##########################  Create Secure Console  ##############################

function create_secure_console {

	COMPARTMENT=$1

	echo
	echo "Creating.... GRAPHICAL CONSOLE"

        ssc entitlements add-console --compartment-name $COMPARTMENT

	if [ $? != 0 ]; then
		echo "  !!! FAILED TO CREATE SECURE CONSOLE !!!"; echo
		FAILED_WITH_ERRORS=1
	fi
}

###################  Create AD Client Server Role  #######################

function create_AD_client {

	COMPARTMENT=$1
	DOMAIN=$2
	
	echo; echo " Creating.... ACTIVE DIRECTORY CLIENT Role"

        ssc compartments add-active-directory \
        --compartment-name $COMPARTMENT \
        --domain-name $DOMAIN \
        --client-only --force
        
	if [ $? != 0 ]; then
		echo "  !!! FAILED TO CREATE AD CLIENT ROLE !!!"; echo
		FAILED_WITH_ERRORS=1
	fi
}

################### Create an ICMP entititlement #######################

# This function pulls variables from a config file where each line represents an entitlement 
# APPLICATION;PROTO;PORT;DIRECTION;TARGET
# The function then determines if the 
function createICMPRule {

	APPLICATION=${LINE[0]}
	PROTO=${LINE[1]}
	PORT=${LINE[2]}
	DIRECTION=${LINE[3]}
	TARGET=${LINE[4]}
	echo "Creating.... $APPLICATION-${DIRECTION^^}-$PROTO-$PORT-$GROUP - (filter: $TARGET)"

 	if [[ ${DIRECTION^^} == "IN" ]]; then
 		if [[ "$TARGET" != "" ]]; then
 			FILTER="--filter $TARGET"
 		    else
 			    FILTER=""
 	    fi
 	    WHAT="create-netin"

 	elif [[ ${DIRECTION^^} == "OUT" ]]; then
 		if [[ "$TARGET" != "" ]]; then
 			FILTER="--host-or-ip $TARGET"
 		else
 			FILTER="--host-or-ip 0.0.0.0/0"
 		fi
 		WHAT="create-netout"

 	else
 		echo "# Invalid direction supplied: $DIRECTION"
 	fi

    ssc entitlements $WHAT --compartment-name $COMPARTMENT \
    --entitlement-name $APPLICATION-${DIRECTION^^}-$PROTO-$PORT-$GROUP --protocol ${PROTO,,} \
    $FILTER

	if [ $? != 0 ]; then
		echo "  !!! FAILED TO CREATE ENTITLEMENT !!!"; echo
		FAILED_WITH_ERRORS=1
	fi

}


#########################  Create SSH Rule  ############################
#
function createSSHRule {
#
	APPLICATION=${LINE[0]}
	PROTO=${LINE[1]}
	PORT=${LINE[2]}
	DIRECTION=${LINE[3]}
	TARGET=${LINE[4]}

	echo "Creating.... $APPLICATION-${DIRECTION^^}-$PROTO-$PORT-$GROUP - (filter: $TARGET)"

 	if [[ ${DIRECTION^^} == "IN" ]]; then
 		if [[ "$TARGET" != "" ]]; then
 			FILTER="--filter $TARGET"
 		    else
 			    FILTER=""
 	    fi
        WHAT="create-ssh-in"

        ssc entitlements $WHAT --compartment-name $COMPARTMENT $FILTER
#
 	elif [[ ${DIRECTION^^} == "OUT" ]]; then
 		if [[ "$TARGET" != "" ]]; then
 			FILTER="--host-or-ip $TARGET"
 		else
 			FILTER="--host-or-ip 0.0.0.0/0"
 		fi
 		WHAT="create-netout"

        ssc entitlements $WHAT --compartment-name $COMPARTMENT \
        --entitlement-name $APPLICATION-${DIRECTION^^}-$PROTO-$PORT-$GROUP --protocol ${PROTO,,} --port $PORT \
        $FILTER
 	else
 		echo "# Invalid direction supplied: $DIRECTION"
 	fi
#
	if [ $? != 0 ]; then
		echo "  !!! FAILED TO CREATE SSH ENTITLEMENT !!!"; echo
		FAILED_WITH_ERRORS=1
	fi
}


######################### Create Net Rule #############################

## This function pulls variables from a config file where each line represents an entitlement 
# APPLICATION;PROTO;PORT;DIRECTION;TARGET
# The function then identifies if the entitlement is inbound or outbound because they are 
# constructed differently. 
function createNetRule {

	APPLICATION=${LINE[0]}
	PROTO=${LINE[1]}
	PORT=${LINE[2]}
	DIRECTION=${LINE[3]}
	TARGET=${LINE[4]}


	echo "Creating.... $APPLICATION-${DIRECTION^^}-$PROTO-$PORT-$GROUP - (filter: $TARGET)"

 	if [[ ${DIRECTION^^} == "IN" ]]; then
 		if [[ "$TARGET" != "" ]]; then
 			FILTER="--filter $TARGET"
 		    else
 			    FILTER=""
 	    fi
 	    WHAT="create-netin"

 	elif [[ ${DIRECTION^^} == "OUT" ]]; then
 		if [[ "$TARGET" != "" ]]; then
 			FILTER="--host-or-ip $TARGET"
 		else
 			FILTER="--host-or-ip 0.0.0.0/0"
 		fi
 		WHAT="create-netout"

 	else
 		echo "# Invalid direction supplied: $DIRECTION"
 	fi

    ssc entitlements $WHAT --compartment-name $COMPARTMENT \
    --entitlement-name $APPLICATION-${DIRECTION^^}-$PROTO-$PORT-$GROUP \
	--protocol ${PROTO,,} \
	--port $PORT \
    $FILTER

	if [ $? != 0 ]; then
		echo "  !!! FAILED TO CREATE ENTITLEMENT !!!"
		FAILED_WITH_ERRORS=1
	fi
}


############## Delete entitlements listed in a file ####################

function delete_old_ent {
	# Set Variables
	COMPARTMENT=$1


	echo
	echo "################################  Deleting Entitlements  #################################"
	echo
	# Read all the entitlement names in a compartment excluding default and AD role entitlements
	CURRENT_ENTITLEMENTS=$(ssc entitlements show --compartment-name $COMPARTMENT \
	--columns 'Entitlement Name' | grep -v -e '^$' | grep -v -e 'role' | grep -v -e 'default' \
	| grep -v -e 'Entitlement Name' | grep -v -e '--------------' | sed '/^\s*$/d' | sort -r)

	# Put the list of current entitlements into a file
	echo "$CURRENT_ENTITLEMENTS" > ./tmp/current_entitlements.txt
	echo

	# Compare the current entitlements one by one against the list of old entitlement names

	while read CURRENT_ENTITLEMENT ; do
		if grep -q -w "$CURRENT_ENTITLEMENT" ./configs/old_base_ent_intuit.txt ; then
			echo; echo "MATCH !!! $CURRENT_ENTITLEMENT - NOW DELETING"
			ssc entitlements delete --compartment-name $COMPARTMENT --entitlement-name $CURRENT_ENTITLEMENT --force
		fi
	done < ./tmp/current_entitlements.txt

	# Delete AD Client Role
	echo; echo "AD CLIENT ROLE - NOW DELETING"
	ssc compartments delete-role --compartment-name $COMPARTMENT --role active-directory --force
	# The above command will be depricated and replaced by    
	# ssc compartments delete-role --compartment-name NAME --role-name ROLE-NAME --force in version 1.5

	# Delte Secure Console
	echo; echo " SECURE CONSOLE - NOW DELETING"
	ssc entitlements delete-console --compartment-name $COMPARTMENT --force
}


######################## Delete Net Rule #################################
#
function deleteNetRule {

	DIRECTION=$1
	PROTO=$2
	PORT=$3

	echo "- NET-$DIRECTION - Deleting $PROTO / $PORT"

 	if [[ $DIRECTION -eq "in" ]]; then
 		WHAT="create-netin"
 	elif [[ $DIRECTION -eq "out" ]]; then
 		WHAT="create-netout"
 	else
 		echo "# Invalid direction supplied: $DIRECTION"
 	fi

    ssc entitlements delete --compartment-name $COMPARTMENT \
    --entitlement-name -$DIRECTION-$PROTO-$PORT-1 --force

	if [ $? != 0 ]; then
		echo "  !!! FAILED TO DELETE ENTITLEMENT !!!"
		exit 1
	fi
}


###################### Disable an entitlement ############################
#
function disable_entitlement {

	COMPARTMENT=$1
	ENTITLEMENT=$2

	echo
	echo "X DISABLE - $ENTITLEMENT IN COMPARTMENT $COMPARTMENT"

    ssc entitlements disable --compartment-name $COMPARTMENT \
    --entitlement-name $ENTITLEMENT

	if [ $? != 0 ]; then
		echo "  !!! FAILED TO DISABLE ENTITLEMENT !!!"
		exit 1
	fi
}


######################### Enable an entitlement ###########################
#
function enableEnt {

	COMPARTMENT=$1
	ENTITLEMENT=$2

	echo
	echo "! ENABLE - $ENTITLEMENT IN COMPARTMENT $COMPARTMENT"

    ssc entitlements enable --compartment-name $COMPARTMENT \
    --entitlement-name $ENTITLEMENT

	if [ $? != 0 ]; then
		echo "  !!! FAILED TO ENABLE ENTITLEMENT !!!"
		exit 1
	fi
}


###################### Show all entitlements ##############################
#
function showEnts {
	echo
	ssc entitlements show --compartment-name $COMPARTMENT \
	--columns 'Entitlement Name','Protocol','Port','Direction','Source or Destination'
}


############## Create stock Centos compartment - from CDN ##################
#
function createCompartmentDemoCDN {
	SERVER=$1
	echo "Creating compartment $COMPARTMENT on server $SERVER"

ssc --trace compartments create --compartment-name $COMPARTMENT \
 --compartment-title "$USER Centos test compartment" \
 --description "$USER Centos test compartment. Created from script." \
 --os-type linux \
 --cdn-os-name centos-ci \
 --src-datastore cdn \
 --vcpus 1 \
 --server $SERVER $OPTIONAL
}


#########################  Create Compartment  ############################
#
function createCompartment {
	COMPARTMENT=$1
	SERVER=$2
	DATASTORE=$3
	SRC_IMAGE_FILEPATH=$4
	VCPUS=$5
	MEMORY=$6

	echo "Creating compartment $COMPARTMENT on server $SERVER "; echo; sleep 2

	ssc compartments create --compartment-name $COMPARTMENT \
	--compartment-title $COMPARTMENT \
	--description "Created from script." \
	--os-type linux \
	--src-datastore $DATASTORE \
	--src-image-filepath $SRC_IMAGE_FILEPATH \
	--vcpus $VCPUS \
	--server $SERVER
	
	sleep 2
}


#########################  Show List of all Servers  ########################
function showallservers  {
    echo
	echo "##############################  Showing All Servers  #################################"
    echo
    ssc servers show-resources \
    --columns 'Server ID','Server FQDN','Compute (Available)','Memory (Available)','Storage (Available)'
}


######################  Show List of all Compartments  #####################
function showallcompartments  {
    echo
	echo "#############################  Showing All Compartments  ###############################"
    echo
    ssc compartments show --columns 'Title'
	ALL_COMPARTMENTS=`ssc compartments show --columns 'Title'`
}


#######################  Show List of all Active Datastores #######################
function showalldatastores {
    echo
	echo "##############################  Showing All Datastores  #################################"
	echo
    ssc datastores show | grep -v -e 'Inactive'
	ALL_DATASTORES=`ssc datastores show | grep -v -e 'Inactive'`
}


###################  List entitlement names -server role  ###################
function list_ent_names  {
    echo
	echo "#################################  SHOWING ENTITLEMENTS  #################################"
    echo
    ALL_ENTITLEMENTS=$(ssc --list entitlements show --compartment-name $1 \
	--columns name | awk '{ print $3 }' | grep -v -e '^$' | grep -v -e 'role')
	echo "$ALL_ENTITLEMENTS"
}


################  Backup entitlements on current compartment  ###############
function backup_ents_to_file {
	COMPARTMENT=$1
	BACKUP_DATE=$(date +%Y-%m-%d)
	echo
	echo "############### Backing Up Entitlements for $COMPARTMENT #################"
	echo
	BACKUP="$(ssc entitlements show --compartment-name $COMPARTMENT \
	--columns 'Entitlement Name','Protocol','Port','Direction','Source or Destination')"
	echo "$BACKUP" > ./backups/"$COMPARTMENT"_backup_"$BACKUP_DATE".txt
	echo; echo "+++++++++++++++++++++++++++++++  BACKUP SUCCESSFUL  +++++++++++++++++++++++++++++++++++++"
}

########################  Check Compartment Exists  #########################
# CHECK Compartment VALIDITY  -  Checks if compartment already exists
function check_compartment_validity {
	COMPARTMENT=$1
	COMPARTMENT_LIST=$(ssc compartments show --columns 'Compartment Name' | grep -m1 -e "$COMPARTMENT")

	if [[ "${COMPARTMENT_LIST}" == *"${COMPARTMENT}"* ]]; then
		echo "  COMPARTMENT CHECK  ====  INVALID COMPARTMENT NAME: Compartment name already exists"; sleep 1
		INVALID_INPUT=1
	else
		echo "  COMPARTMENT CHECK  ====  VALID COMPARTMENT ($COMPARTMENT)"; sleep 1   
	fi
}

########################  Check Version of SSC CLI  ########################
function check_cli_version {
	echo
	echo "###################################  CHECKING VERSION  ##################################"

	VERSION=$(ssc -v)
	if [[ "$VERSION" == *"1.4.0"* ]]; then
		echo; echo "!!!  SSC version out of date! Please upgrade before proceeding   !!!"
		echo "      Please perform sudo yum update skysecure-cli to upgrade"
		echo
		exit
	else
		echo "Supported version of SSC CLI Tool"	
	fi
}

##########################  Check bad entry or failure #####################
function failure_check {
	case $? in
		"1")
			echo
			echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			echo "                      DEPLOYMENT FAILED - DELETING FAILED COMPARTMENT"
			ssc compartments delete --identifier $COMPARTMENT
			;;
		"2")
			echo
			echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			echo "                DEPLOYMENT FAILED - PLEASE CHECK YOUR INPUT AND TRY AGAIN"
			sleep 2
			echo "       Command should be in the format below where entries in brackets are your input"
			echo
			sleep 2
			echo "                                       COMMAND USAGE"
			echo "  ./deploy-compartment-with-entitlements.sh [COMPARTMENT_NAME] [SERVER] [APPLICATION] [DATACENTER]"
			echo
			exit 1
			;;
	esac
}
