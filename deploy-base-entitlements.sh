#!/usr/bin/env bash

. ./sscfunctions.sh    # Location of fuctions called in this script

##############################  Set Variables  ############################

COMPARTMENT=$1              # Compartment name
APP=${2^^}                  # Application name (Currently BASE, SPLUNK, or JIRA)

GROUP="BASE"                # Set group these entitlements will be part of
FILE="./configs/BASE.txt"   # Location of file containing BASE entitlements
DOMAIN="corp.foo.com"       # AD Domain for Active Director Client role
################################# ACTIONS #################################

# Deploy BASE entitlements from config file

######################  DEPLOY BASE ENTITLEMENTS  #########################
echo; echo; echo
echo "################################### CREATING BASE ENTITLEMENTS #####################################"
sleep 1
read_current_entitlements
#Compare current entitlements to BASE entitlements and add the missing BASE entitlements to leftover-entitlements.txt
comm -2 -3 $FILE ./tmp/current_entitlements.txt > ./tmp/leftover-entitlements.txt
# Read entitlements line by line from config file
# Configuration file format: APPLICATION(0);PROTOCOL(1);PORT(2);DIRECTION(3);TARGET(4)

while IFS=';' read -r -a LINE; do
    if [[ ${LINE[0]} == *"ssh"* ]]; then
            createSSHRule $LINE
    elif [[ ${LINE[1]} == "ICMP" ]]; then
            createICMPRule $LINE
    else
            createNetRule $LINE
    fi
done < ./tmp/leftover-entitlements.txt
       
# Creating AD Client Role
create_AD_client $COMPARTMENT $DOMAIN
#
# Creating Secure Console
create_secure_console $COMPARTMENT
#
# Disable DHCP Entitlement
echo; echo "DISABLE DEFAULT DHCP ENTITLEMENT"
disable_entitlement $COMPARTMENT default-policy-dhcp-out

# Set security posture to whitelist-mode
set_security_posture $COMPARTMENT whitelist-mode

# Check to see if there were deployment errors
if [[ "$FAILED_WITH_ERRORS" == "1" ]]; then
    echo; echo "FAILED TO CREATE ALL ENTITLEMENTS --  PLEASE VERIFY CONFIGURATION"
fi

echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  DONE CREATING BASE ENTITLEMENTS  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
#Cleanup of temp files

sleep 2