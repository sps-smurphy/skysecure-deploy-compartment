#!/usr/bin/env bash

. ./sscfunctions.sh    # Location of fuctions called in this script

##############################  Set Variables  ############################

COMPARTMENT=$1         # Compartment name
APP=${2^^}             # Application name (Currently BASE, SPLUNK, or JIRA)

GROUP="$APP"
FILE="./configs/$APP.csv"
################################# ACTIONS #################################

# Check to see if the compartment is BASE only
if [ "$APP" == "BASE" ]; then
    echo; echo
    exit 0
fi
######################  DEPLOY APP ENTITLEMENTS  #########################
echo; echo; echo; echo
echo "############################## CREATING $APP ENTITLEMENTS ##########################################"
sleep 1

while IFS= read -a LINE; do
    APPLICATION="$(echo $LINE | awk -F';' '{print $1}')"
    PROTO="$(echo $LINE | awk -F';' '{print $2}')"
    PORT="$(echo $LINE | awk -F';' '{print $3}')"
    DIRECTION="$(echo $LINE | awk -F';' '{print $4}')"
    TARGET="$(echo $LINE | awk -F';' '{print $5}')"

    echo
    if [[ ${APPLICATION} == *"ssh"* ]]; then
        createSSHRule $LINE
    elif [[ $PROTO == "ICMP" ]]; then
        createICMPRule $LINE
    else
        createNetRule $LINE
    fi
done < $FILE

echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  DONE CREATING $APP ENTITLEMENTS  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo
sleep 3



