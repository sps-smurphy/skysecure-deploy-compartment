#!/usr/bin/env bash

. ./sscfunctions.sh    # Location of fuctions called in this script

##############################  Set Variables  ############################

COMPARTMENT=$1              # Compartment name
APP=${2^^}                  # Application name (Currently BASE, SPLUNK, or JIRA)

GROUP="$APP"                # Set group these entitlements will be part of
FILE="./configs/$APP.csv"   # Location of file containing APP entitlements
################################# ACTIONS #################################

# Check to see if the compartment is BASE only
if [ "$APP" == "BASE" ]; then
    echo; echo
    exit 0
fi
######################  DEPLOY APP ENTITLEMENTS  #########################
echo; echo; echo
echo "############################## CREATING $APP ENTITLEMENTS ##########################################"
sleep 1
# Read entitlements line by line from config file
# Configuration file format: APPLICATION(0);PROTOCOL(1);PORT(2);DIRECTION(3);TARGET(4)

while IFS=';' read -r -a LINE; do
    echo ${LINE[0]} ${LINE[1]} ${LINE[2]} ${LINE[3]} ${LINE[4]}
        if [[ ${LINE[0]} == *"ssh"* ]]; then
            createSSHRule $LINE
        elif [[ ${LINE[1]} == "ICMP" ]]; then
            createICMPRule $LINE
        else
            createNetRule $LINE
        fi
done < $FILE

echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  DONE CREATING $APP ENTITLEMENTS  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo
sleep 2



