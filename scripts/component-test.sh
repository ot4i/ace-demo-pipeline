#!/bin/bash
#
# Copyright (c) 2020 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)
#
# Relies on CT_JDBC_USR and CT_JDBC_PSW being set in the environment

if [ ! -n "$MQSI_WORKPATH" ]
then
    . /opt/ibm/ace-11/server/bin/mqsiprofile
fi

echo "Build JCN code"
ant -f TeaSharedLibraryJava/build.xml

if [ "$?" != "0" ]; then
    echo "ant failed; exiting"
    exit 1
fi

echo "Build application and shared library into BAR file"
ant -f TeaRESTApplication/build.xml

if [ "$?" != "0" ]; then
    echo "ant failed; exiting"
    exit 1
fi

echo "Build test scaffold and shared library into BAR file"
ant -f TeaTestsScaffold/build.xml

if [ "$?" != "0" ]; then
    echo "ant failed; exiting"
    exit 1
fi


echo "Deploy test scaffold to server"
rm -rf /tmp/ct-work-dir
mqsicreateworkdir /tmp/ct-work-dir
mqsibar -c -w /tmp/ct-work-dir -a  tea-scaffold.bar
mqsisetdbparms -w /tmp/ct-work-dir -n jdbc::tea -u ${CT_JDBC_USR} -p ${CT_JDBC_PSW}

mkdir /tmp/ct-work-dir/run/CTPolicies
echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:policyProjectDescriptor xmlns="http://com.ibm.etools.mft.descriptor.base" xmlns:ns2="http://com.ibm.etools.mft.descriptor.policyProject"><references/></ns2:policyProjectDescriptor>' > /tmp/ct-work-dir/run/CTPolicies/policy.descriptor

cp ${WORKSPACE}/scripts/preprod-container/TEAJDBC.policyxml /tmp/ct-work-dir/run/CTPolicies/TEAJDBC.policyxml
sed -i "s/DATABASE_NAME/USERDB/g" /tmp/ct-work-dir/run/CTPolicies/TEAJDBC.policyxml
sed -i "s/SERVER_NAME/kenya.hursley.uk.ibm.com/g" /tmp/ct-work-dir/run/CTPolicies/TEAJDBC.policyxml
sed -i "s/PORT_NUMBER/50000/g" /tmp/ct-work-dir/run/CTPolicies/TEAJDBC.policyxml

sed -i "s/#policyProject: 'DefaultPolicies'/policyProject: 'CTPolicies'/g" /tmp/ct-work-dir/server.conf.yaml

echo "Run tests"
find /tmp/ct-work-dir -type f -print

scripts/start-server.sh /tmp/ct-work-dir
if [ "$?" != "0" ]; then
    echo "server start failed; exiting"
    exit 1
fi
sleep 5
echo "Attempting to call the service"

curl -i http://localhost:7800/ctJDBC/0 > /tmp/curl.out 2>/dev/null

echo Service returned:
cat /tmp/curl.out
echo

echo "Killing server"
ps -ef | grep IntegrationServer | grep ct-work-dir | cut -c8-15 | xargs kill -9 

grep -q "200 OK" /tmp/curl.out
if [ "$?" != "0" ]; then
    echo "testing failed"
    exit 1
else
    echo "testing passed"
    exit 0
fi
