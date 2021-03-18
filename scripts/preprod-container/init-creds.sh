#!/bin/bash
#
# Copyright (c) 2020 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)
#

echo "Pulling in secrets"

set +x

mkdir /home/aceuser/ace-server/run/PreProdPolicies
echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:policyProjectDescriptor xmlns="http://com.ibm.etools.mft.descriptor.base" xmlns:ns2="http://com.ibm.etools.mft.descriptor.policyProject"><references/></ns2:policyProjectDescriptor>' > /home/aceuser/ace-server/run/PreProdPolicies/policy.descriptor

export TEMPLATE_POLICYXML=/tmp/TEAJDBC.policyxml

if [[ -e "/home/aceuser/ace-server/TEAJDBC.policyxml" ]]
then
    # Maven s2i
    export TEMPLATE_POLICYXML=/home/aceuser/ace-server/TEAJDBC.policyxml
fi

echo "policy ${TEMPLATE_POLICYXML} before"
cat ${TEMPLATE_POLICYXML}
sed -i "s/DATABASE_NAME/`cat /run/secrets/jdbc/databaseName`/g" ${TEMPLATE_POLICYXML}
sed -i "s/SERVER_NAME/`cat /run/secrets/jdbc/serverName`/g" ${TEMPLATE_POLICYXML}
sed -i "s/PORT_NUMBER/`cat /run/secrets/jdbc/portNumber`/g" ${TEMPLATE_POLICYXML}

echo "policy ${TEMPLATE_POLICYXML} after"
cat ${TEMPLATE_POLICYXML}
cp ${TEMPLATE_POLICYXML} /home/aceuser/ace-server/run/PreProdPolicies/

mqsisetdbparms -w /home/aceuser/ace-server -n jdbc::tea -u `cat /run/secrets/jdbc/USERID` -p `cat /run/secrets/jdbc/PASSWORD`

sed -i "s/#policyProject: 'DefaultPolicies'/policyProject: 'PreProdPolicies'/g" /home/aceuser/ace-server/server.conf.yaml
