#!/usr/bin/env bash

. ./sscfunctions.sh    # Location of fuctions called in this script

##############################  Set Variables  ############################

COMPARTMENT=$1

################################# ACTIONS #################################
echo "    V"; sleep 1; echo "    V"; sleep 1; echo "    V"; sleep 1
echo "    V"; sleep 1; echo "    V"; sleep 1; echo "    V"; sleep 1
echo "################################  SHOW ENTITLEMENTS  ###############################################"
sleep 2
# Show all of the entitlements on the compartment
showEnts
echo
sleep 5
echo "################################  STARTING COMPARTMENT  #############################################"
ssc compartments start --identifier $COMPARTMENT --force
echo
sleep 5
ssc compartments show --compartment-name $COMPARTMENT | grep 'Status' | grep -v -e 'Entitlement Name'





