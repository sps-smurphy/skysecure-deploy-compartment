#!/usr/bin/env bash

. ./sscfunctions.sh    # Location of fuctions called in this script

##############################  Set Variables  ############################

COMPARTMENT=$1         # Compartment name
SERVER=${2^^}          # Server ID or FQDN
DATACENTER=${3^^}      # Datacenter location where image is stored  (LasVegas or Quincy)
APP=${4^^}             # Application name (Currently BASE, SPLUNK, or JIRA)

GROUP="BASE"
FILE="./configs/BASE.csv"
################################# ACTIONS #################################

#######################  DEPLOY BASE ENTITLEMENTS  ########################

# Deploy BASE entitlements from config file
echo; echo; echo
echo "################################### CREATING BASE ENTITLEMENTS #####################################"
sleep 1

while IFS= read -a LINE; do
    APPLICATION="$(echo $LINE | awk -F';' '{print $1}')"
    PROTO="$(echo $LINE | awk -F';' '{print $2}')"
    PORT="$(echo $LINE | awk -F';' '{print $3}')"
    DIRECTION="$(echo $LINE | awk -F';' '{print $4}')"
    TARGET="$(echo $LINE | awk -F';' '{print $5}')"
    RET=1
    echo
    until [[ ${RET} -eq 0]]; do
        if [[ ${APPLICATION} == *"ssh"* ]]; then
            createSSHRule $LINE
        elif [[ $PROTO == "ICMP" ]]; then
            createICMPRule $LINE
        else
            createNetRule $LINE
        fi
        RET=$?
        sleep 2; echo; echo "Retrying............"
    done    
done < $FILE

# Creating AD Client Role
create_secure_console $COMPARTMENT
#
# Creating Secure Console
create_AD_client $COMPARTMENT
#
# Disable DHCP Entitlement
echo; echo "DISABLE DEFAULT DHCP ENTITLEMENT"
disableEnt $COMPARTMENT default-policy-dhcp-out

# Check to see if there were deployment errors
if [[ "$FAILED_WITH_ERRORS" == "1" ]]; then
    echo; echo "FAILED TO CREATE ALL ENTITLEMENTS --  PLEASE VERIFY CONFIGURATION"
fi
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  DONE CREATING BASE ENTITLEMENTS  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
sleep 1