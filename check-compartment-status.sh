#!/usr/bin/env bash

. ./sscfunctions.sh    # Location of fuctions called in this script

##############################  Set Variables  ############################

COMPARTMENT=$1

################################# ACTIONS #################################

COUNTER=0
while [[ "$STATUS" != "" ]]; do
    STATUS=$(ssc compartments show --compartment-name $COMPARTMENT | awk '/Status/ && /:/')
    echo -ne "$STATUS\033[0K\r"
    sleep 5
done
echo "DONE"






