#!/usr/bin/env bash

. ./sscfunctions.sh    # Functions called in this script

##########################  Set Variables  ############################
COMPARTMENT=$1
COMPARTMENT_LIST=$(ssc compartments show --columns 'Compartment Name' | grep -m1 -e "$COMPARTMENT")
INVALID_INPUT=0
################################ ACTIONS ################################
# Check SSC CLI version
check_cli_version
sleep 1

# Check if compartment exists and fail if it does not exist

if [[ "${COMPARTMENT_LIST}" == *"${COMPARTMENT}"* ]]; then
    echo
    echo "  Compartment $COMPARTMENT exists and is valid!!"
else
    echo;echo "Compartment doesn't exist.  Please check the spelling and retry."
    exit 2
fi

# Backup existing entitlements
backup_ents_to_file $COMPARTMENT
sleep 1

# For each entitlement name in the file old_base_ent_intuit.txt delete that entitlement
delete_old_ent $COMPARTMENT
sleep 1

# List all remaining entitlements
list_ent_names $COMPARTMENT
sleep 1

# Deploy BASE entitlements from config file
#####################  Deploy BASE entitlements  ########################
sh ./deploy-base-entitlements.sh $COMPARTMENT
sleep 1
echo
# Show entitlements
showEnts