#!/usr/bin/env bash

. ./sscfunctions.sh    # Location of fuctions called in this script

##########################  Set Variables  ############################

COMPARTMENT=$1         # Compartment name
SERVER=${2^^}          # Server ID
DATACENTER=${3^^}      # Datacenter location where image is stored  (LasVegas or Quincy)
APP=${4^^}             # Application name (Currently BASE, SPLUNK, or JIRA)

INVALID_INPUT=0

# Source datastores for different datacenters
LVDC_DATASTORE="LVDC-PRODUCTION-DEPLOYMENT"
QUINCY_DATASTORE="QDC-PRODUCTION-DEPLOYMENT"
LAB_DATASTORE="Lab-deployment"
SP_DATASTORE="linux-mirror-demosps1-com"

# Source image filepaths for different applications
BASE_SRC_IMAGE_FILEPATH="skyprhel7u2dhcp-disk1.vmdk"
SPLUNK_SRC_IMAGE_FILEPATH="skyprhel7u2dhcp-disk1.vmdk"
JIRA_SRC_IMAGE_FILEPATH="skyprhel7u2dhcp-disk1.vmdk"
SP_SRC_IMAGE_FILEPATH="/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2c"
################################# ACTIONS #################################
shopt -s nocasematch

######################## CHECK VARIABLE VALIDITY ##########################
echo; echo
echo "#################################  CHECKING VARIABLES  #############################################"
echo
sleep 1

# CHECK Compartment VALIDITY  -  Checks if compartment already exists

check_compartment_validity $COMPARTMENT

# CHECK Server VALIDITY  -  Check if server exists in the enterprise

SERVER_LIST=$(ssc servers show)

if [[ "$SERVER_LIST" == *"${SERVER}"* ]]; then
    echo "  SERVER CHECK  =========  VALID SERVER ($SERVER)"; sleep 1
else
    echo "  SERVER CHECK  =========  INVALID SERVER NAME:  Check the server name and run again"; sleep 1
    INVALID_INPUT=1
fi


# Set App specific variables

if [[ $APP == "SPLUNK" ]]; then
    SRC_IMAGE_FILEPATH="$SPLUNK_SRC_IMAGE_FILEPATH"
    VCPUS=1     # Need to verify if this is the rigth number of CPU's for splunk
    echo "  APPLICATION CHECK  ====  VALID APPLICATION (Splunk)"; sleep 1
elif [[ $APP == "JIRA" ]]; then
    SRC_IMAGE_FILEPATH="$JIRA_SRC_IMAGE_FILEPATH"
    VCPUS=2     # Need to verify if this is the rigth number of CPU's for JIRA
    echo "  APPLICATION CHECK  ====  VALID APPLICATION (JIRA)"; sleep 1
elif [[ $APP == "BASE" ]]; then
    SRC_IMAGE_FILEPATH="$BASE_SRC_IMAGE_FILEPATH"
    VCPUS=2     # Need to verify if this is the rigth number of CPU's for base
    echo "  APPLICATION CHECK  ====  VALID APPLICATION (BASE)"; sleep 1
elif [[ $APP == "SP" ]]; then
    SRC_IMAGE_FILEPATH="$SP_SRC_IMAGE_FILEPATH"
    VCPUS=1     # Need to verify if this is the rigth number of CPU's for base
    echo "  APPLICATION CHECK  ====  VALID APPLICATION (Test Compartment)"; sleep 1
else
    echo "  APPLICATION CHECK  ====  INVALID APPLICATION NAME:  BASE,SPLUNK,and JIRA supported"; sleep 1

    INVALID_INPUT=1
fi

# Check DATACENTER validity

case $DATACENTER in
    "LASVEGAS")
        echo "  DATACENTER CHECK  =====  VALID DATACENTER ($DATACENTER)"
        DATASTORE="$LVDC_DATASTORE"
        sleep 1
        ;;
    "QUINCY")
        echo "  DATACENTER CHECK  =====  VALID DATACENTER ($DATACENTER)"
        DATASTORE="$QUNICY_DATASTORE"
        sleep 1
        ;;
    "LAB")
        echo "  DATACENTER CHECK  =====  VALID DATACENTER ($DATACENTER)"
        DATASTORE="$LAB_DATASTORE"
        sleep 1
        ;;
    "SP")
        echo "  DATACENTER CHECK  =====  VALID DATACENTER ($DATACENTER)"
        DATASTORE="$SP_DATASTORE"
        sleep 1
        ;;
    *)
        echo "  DATACENTER CHECK  =====  INVALID DATACENTER NAME: Enter LASVEGAS, QUINCY, or LAB for datacenter"
        INVALID_INPUT=1
        ;;
esac

# Check if there were errors and fail if there were any invalid inputs

if [ $INVALID_INPUT == 1 ]; then
    exit 2
else
    echo
    echo "  Configuration check SUCCESSFUL!!"
fi
####################  CREATE COMPARTMENT  ##############################
sleep 1; echo; echo
echo "####################  CREATING COMPARTMENT $COMPARTMENT  #############################"
echo
createCompartment $COMPARTMENT $SERVER $DATASTORE $SRC_IMAGE_FILEPATH $VCPUS





