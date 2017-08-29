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
ssc compartments start --identifier $COMPARTMENT #--force
echo

# Check to see the status of the compartment as it starts

while [[ "$STATUS" != "Status          : Ok - Working properly" ]]; do
    STATUS=$(ssc compartments show --compartment-name $COMPARTMENT | awk '/Status/ && /:/')
    echo -ne "$STATUS\033[0K\r"
    sleep 5
done
echo "Status          : Ok - Working properly"






