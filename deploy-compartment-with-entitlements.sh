#!/usr/bin/env bash

. ./sscfunctions.sh    # Location of fuctions called in this script

##############################  Set Variables  ############################

COMPARTMENT=$1
SERVER=$2
DATACENTER=$3
APP=$4

##############################  INTRODUCTION  ################################
echo; echo; echo; echo
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~  CREATING COMPARTMENT $COMPARTMENT WITH $APP ENTITLEMENTS  ~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
sleep 1

################################ CREATE COMPARTMENT ################################
sh ./deploy-compartment.sh $COMPARTMENT $SERVER $DATACENTER $APP 

failure_check
############################# DEPLOY BASE ENTITLEMENTS #############################
sh ./deploy-base-entitlements.sh $COMPARTMENT $APP 

failure_check
############################  DEPLOY APP ENTITLEMENTS  #############################
sh ./deploy-app-entitlements.sh $COMPARTMENT $APP

failure_check
###############################  START COMPARTMENT  ################################
sh ./deploy-start-compartment.sh $COMPARTMENT


echo "##################################  SUCCESSFULLY COMPLETED  #######################################"




