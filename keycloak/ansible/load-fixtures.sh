#!/bin/bash
# load-fixtures.sh

###################
# Import Fixtures #
###################

# try to authenticate until keycloak is correctly started :

n=0
until [ $n -ge 5 ]
do
   ansible-playbook -l localhost /opt/ansible/import-fixtures.yml --tags "authenticate" && break
   n=$[$n+1]
   # sleep 5
done
if (( n > 5 )); then
  echo "Could not athenticate on keycloak server. Probably not started !"
  exit 1
else  
  echo "Correctly authenticated on keycloak server !"
fi

# then we can continue the rest of our playbook

ansible-playbook -l localhost /opt/ansible/import-fixtures.yml --skip-tags "authenticate"