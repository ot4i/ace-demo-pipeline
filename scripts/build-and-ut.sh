#!/bin/bash
#
# Copyright (c) 2020 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)
#

if [ ! -n "$MQSI_WORKPATH" ]
then
    . /opt/ibm/ace-11/server/bin/mqsiprofile
fi

if [ ! -n "$WORKSPACE" ]
then
    # Probably a Travis build
    echo "Assinging $PWD as WORKSPACE; TRAVIS_JOB_NUMBER is $TRAVIS_JOB_NUMBER"
    export WORKSPACE=$PWD
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
rm -rf /tmp/test-work-dir
mqsicreateworkdir /tmp/test-work-dir
mqsibar -c -w /tmp/test-work-dir -a  tea-scaffold.bar

scripts/start-server.sh /tmp/test-work-dir
if [ "$?" != "0" ]; then
    echo "server start failed; exiting"
    exit 1
fi

export TEA_TEST_WORK_DIR=/tmp/test-work-dir
export TEA_TEST_RESOURCE_DIR=${WORKSPACE}/TeaTests/test-data
# Not sure why we need to do this, but build.xml task classpath doesn't seem to work
export CLASSPATH=${WORKSPACE}/TeaTests/ant-junit.jar:${WORKSPACE}/TeaTests/ant-junit4.jar:$CLASSPATH

echo "Build tests and run them"
ant -lib ${WORKSPACE}/TeaTests -f TeaTests/build.xml

if [ "$?" != "0" ]; then
    echo "testing failed"
    echo "Killing server"
    ps -ef | grep IntegrationServer | grep test-work-dir | cut -c8-15 | xargs kill -9 

    # This is slightly hacky, but allows us to force Blue Ocean pipelines to fail later; if we fail now
    # in this stage then the JUnit results don't get picked up.
    echo "Triggering failure after the JUnit results have been picked up"
    echo "#!/bin/bash" > scripts/force-failure-on-junit-fail.sh
    echo "echo 'JUnit failure'" >> scripts/force-failure-on-junit-fail.sh
    echo "exit 1" >> scripts/force-failure-on-junit-fail.sh
    chmod 775 scripts/force-failure-on-junit-fail.sh

    if [ ! -n "$TRAVIS_JOB_NUMBER" ]
    then
	exit 0
    else
	exit 1
    fi
else
    echo "testing passed"
    echo "Killing server"
    ps -ef | grep IntegrationServer | grep test-work-dir | cut -c8-15 | xargs kill -9 
    exit 0
fi


