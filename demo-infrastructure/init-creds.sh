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


if [[ -e "/mnt/secrets-store/xmlCredentials" ]]
then
    # Azure keyvault - XML format stored directly as a secret
    echo "policy ${TEMPLATE_POLICYXML} before Azure KV mods"
    cat ${TEMPLATE_POLICYXML}
    sed -i "s/DATABASE_NAME/${TEA_DATABASE_NAME}/g" ${TEMPLATE_POLICYXML}
    sed -i "s/SERVER_NAME/${TEA_SERVER_NAME}/g" ${TEMPLATE_POLICYXML}
    sed -i "s/PORT_NUMBER/${TEA_PORT_NUMBER}/g" ${TEMPLATE_POLICYXML}
    
    echo "policy ${TEMPLATE_POLICYXML} after"
    cat ${TEMPLATE_POLICYXML}
    cp ${TEMPLATE_POLICYXML} /home/aceuser/ace-server/run/PreProdPolicies/

    echo "---" >> /home/aceuser/ace-server/overrides/server.conf.yaml
    echo "Credentials:" >> /home/aceuser/ace-server/overrides/server.conf.yaml
    echo "  ExternalCredentialsProviders:" >> /home/aceuser/ace-server/overrides/server.conf.yaml
    echo "    TeaJDBCAzureKV:" >> /home/aceuser/ace-server/overrides/server.conf.yaml
    echo "      loadAllCredentialsCommand: '/home/aceuser/ace-server/read-xml-creds.sh'" >> /home/aceuser/ace-server/overrides/server.conf.yaml
    echo "      loadAllCredentialsFormat: 'xml'" >> /home/aceuser/ace-server/overrides/server.conf.yaml
    echo ""  >> /home/aceuser/ace-server/overrides/server.conf.yaml
fi

if [[ -e "/vault/secrets/tea" ]]
then
    # Hashicorp Vault

    echo "policy ${TEMPLATE_POLICYXML} before Azure KV mods"
    cat ${TEMPLATE_POLICYXML}
    sed -i "s/DATABASE_NAME/${TEA_DATABASE_NAME}/g" ${TEMPLATE_POLICYXML}
    sed -i "s/SERVER_NAME/${TEA_SERVER_NAME}/g" ${TEMPLATE_POLICYXML}
    sed -i "s/PORT_NUMBER/${TEA_PORT_NUMBER}/g" ${TEMPLATE_POLICYXML}
    
    echo "policy ${TEMPLATE_POLICYXML} after"
    cat ${TEMPLATE_POLICYXML}
    cp ${TEMPLATE_POLICYXML} /home/aceuser/ace-server/run/PreProdPolicies/

    echo "---" >> /home/aceuser/ace-server/overrides/server.conf.yaml
    echo "Credentials:" >> /home/aceuser/ace-server/overrides/server.conf.yaml
    echo "  ExternalCredentialsProviders:" >> /home/aceuser/ace-server/overrides/server.conf.yaml
    echo "    TeaJDBCHashiCorp:" >> /home/aceuser/ace-server/overrides/server.conf.yaml
    echo "      loadAllCredentialsCommand: '/home/aceuser/ace-server/read-hashicorp-creds.sh'" >> /home/aceuser/ace-server/overrides/server.conf.yaml
    echo "      loadAllCredentialsFormat: 'yaml'" >> /home/aceuser/ace-server/overrides/server.conf.yaml
    echo ""  >> /home/aceuser/ace-server/overrides/server.conf.yaml    
fi

if [[ -e "/work/jdbc/serverName" ]]
then
    # Component test DB2 container
    echo "Component test DB2 container"
    echo "policy ${TEMPLATE_POLICYXML} before"
    cat ${TEMPLATE_POLICYXML}
    sed -i "s/DATABASE_NAME/`cat /work/jdbc/databaseName`/g" ${TEMPLATE_POLICYXML}
    sed -i "s/SERVER_NAME/`cat /work/jdbc/serverName`/g" ${TEMPLATE_POLICYXML}
    sed -i "s/PORT_NUMBER/`cat /work/jdbc/portNumber`/g" ${TEMPLATE_POLICYXML}
    sed -i "s/sslConnection=true/sslConnection=false/g" ${TEMPLATE_POLICYXML}
    
    echo "policy ${TEMPLATE_POLICYXML} after"
    cat ${TEMPLATE_POLICYXML}
    cp ${TEMPLATE_POLICYXML} /home/aceuser/ace-server/run/PreProdPolicies/
    
    mqsisetdbparms -w /home/aceuser/ace-server -n jdbc::tea -u `cat /work/jdbc/USERID` -p `cat /work/jdbc/PASSWORD`
fi

if [[ -e "/home/aceuser/ace-server/run/PreProdPolicies/TEAJDBC.policyxml" ]]
then
    # Already completed
    echo "Not reading kube secrets"
else
    # Original kube secrets approach
    echo "policy ${TEMPLATE_POLICYXML} before"
    cat ${TEMPLATE_POLICYXML}
    sed -i "s/DATABASE_NAME/`cat /run/secrets/jdbc/databaseName`/g" ${TEMPLATE_POLICYXML}
    sed -i "s/SERVER_NAME/`cat /run/secrets/jdbc/serverName`/g" ${TEMPLATE_POLICYXML}
    sed -i "s/PORT_NUMBER/`cat /run/secrets/jdbc/portNumber`/g" ${TEMPLATE_POLICYXML}
    
    echo "policy ${TEMPLATE_POLICYXML} after"
    cat ${TEMPLATE_POLICYXML}
    cp ${TEMPLATE_POLICYXML} /home/aceuser/ace-server/run/PreProdPolicies/
    
    mqsisetdbparms -w /home/aceuser/ace-server -n jdbc::tea -u `cat /run/secrets/jdbc/USERID` -p `cat /run/secrets/jdbc/PASSWORD`
fi


sed -i "s/#policyProject: 'DefaultPolicies'/policyProject: 'PreProdPolicies'/g" /home/aceuser/ace-server/server.conf.yaml
