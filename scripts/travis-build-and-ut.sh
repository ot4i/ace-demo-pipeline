#!/bin/bash
#
# Copyright (c) 2020 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)
#

if [ ! -n "$MQSI_WORKPATH" ]
then
    . /opt/ibm/ace-13/server/bin/mqsiprofile
fi

if [ ! -n "$WORKSPACE" ]
then
    # Probably a Travis build
    echo "Assigning $PWD as WORKSPACE; TRAVIS_JOB_NUMBER is $TRAVIS_JOB_NUMBER"
    export WORKSPACE=$PWD
fi

mvn verify

if [ "$?" != "0" ]; then
    echo "testing failed"

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
    exit 0
fi


