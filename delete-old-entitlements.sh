#!/usr/bin/env bash
######################  SET VARIABLES  #############################
COMPARTMENT=$1
echo
echo "#################  Deleting Entitlements  ##################"
echo
# Read all the entitlement names in a compartment
CURRENT_ENTITLEMENTS=$(ssc entitlements show --compartment-name $COMPARTMENT \
--columns 'Entitlement Name' | grep -v -e '^$' | grep -v -e 'role' | grep -v -e 'default' \
| grep -v -e 'Entitlement Name' | grep -v -e '--------------' | sed '/^\s*$/d' | sort -r)
echo "$CURRENT_ENTITLEMENTS" > current_entitlements.txt
echo

# Check the first name in the list against the entitlements in the compartment
# If the name in the list doesn't match then go to the next one in the list
# If the name does match then delete it and go on to the next one in the list

while read CURRENT_ENTITLEMENT ; do
    if grep -q -w "$CURRENT_ENTITLEMENT" old_base_ent_intuit.txt ; then
        echo "MATCH !!! $CURRENT_ENTITLEMENT - NOW DELETING"
	  	echo "ssc entitlements delete --compartment-name $COMPARTMENT --entitlement-name $CURRENT_ENTITLEMENT --force"
	 	ssc entitlements delete --compartment-name $COMPARTMENT --entitlement-name $CURRENT_ENTITLEMENT --force
    fi
done < current_entitlements.txt

# echo
# echo "*****************  CHECKING  ************************"
# while read OLD_BASE_ENT ; do
# 	if [[ "$CURRENT_ENTITLEMENTS" =~ "$OLD_BASE_ENT" ]]; then
# 		echo "MATCH !!! $OLD_BASE_ENT"
# 	fi
# done < old_base_ent_intuit.txt




# 	# if  [["$MATCH" != "" ]] ; then 
# 	# 	echo "MATCH!!!! - NOW DELETING"
# 	# 	echo "ssc entitlements delete --compartment-name $1 --entitlement-name $MATCH --force"
# 	# 	ssc entitlements delete --compartment-name $1 --entitlement-name $MATCH --force
# 	# fi