#!/usr/bin/env bash

. ./sscfunctions.sh    # Functions called in this script

##########################  Set Variables  ############################
COMPARTMENT=$1

################################ ACTIONS ################################
# Check SSC CLI version
check_cli_version
sleep 1

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