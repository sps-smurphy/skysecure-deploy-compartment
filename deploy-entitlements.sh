#!/usr/bin/env bash

. ./sscfunctions.sh    # Location of fuctions called in this script

##############################  Set Variables  ############################

COMPARTMENT=$1              # Compartment name
APP=${2^^}                  # Application name (Currently BASE, SPLUNK, or JIRA)

FILE="./configs/$APP.csv"   # Location of file containing APP entitlements
################################# ACTIONS #################################

######################  DEPLOY ENTITLEMENT  #########################
echo; echo; echo
echo "############################## CREATING $APP ENTITLEMENTS ##########################################"

# Read entitlements line by line from config file
# Configuration file format: APPLICATION(0);PROTOCOL(1);PORT(2);DIRECTION(3);TARGET(4)

while IFS=';' read -r -a LINE; do
            createNetRule $LINE
done < $FILE

echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  DONE CREATING $APP ENTITLEMENTS  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo



