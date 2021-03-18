#!/bin/bash
#
# Copyright (c) 2020 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)
#

echo Starting test run

# Internal dev pipeline
export LICENSE=accept

if [ ! -n "$MQSI_WORKPATH" ]
then
    . /opt/ibm/ace-11/server/bin/mqsiprofile
fi


# Copy them into the right location to be picked up by the docker build
mkdir -p temp/bars/

# Built in previous stages
cp TeaRESTApplication/tea.bar temp/bars
if [ "$?" != "0" ]; then
    echo "Application BAR build failed - aborting"
    exit 1
fi
cp TeaSharedLibrary/tea-shlib.bar temp/bars
if [ "$?" != "0" ]; then
    echo "Shared library BAR build failed - aborting"
    exit 1
fi

cp scripts/preprod-container/Dockerfile temp/
cp scripts/preprod-container/*.sh temp/
cp scripts/preprod-container/*xml temp/

export REGISTRY="uk.icr.io/ace-registry"

# set the image name in a variable
IMAGE=tea
VERSION=latest

cd temp
echo "in temp"
find * -ls

ibmcloud login -r eu-gb --apikey $IBMCLOUD_APIKEY
ibmcloud cr login
echo "Current images in registry"
ibmcloud cr images 
# Likely to fail if images don't exist
echo "Likely to fail if images don't exist - not a genuine error"
( ibmcloud cr images --quiet | xargs -n 1 ibmcloud cr image-rm ) || /bin/true
# build the image
docker build --tag ${REGISTRY}/${IMAGE}:${VERSION} . 

if [ "$?" != "0" ]; then
    echo "docker build failed"
    exit 1
else
    echo "docker build succeeded"
fi

# Push to registry

# 
# Issue with IBM Container Registry:
# 
# Error response from daemon: client version 1.40 is too new. Maximum supported API version is 1.39
# 

# Fixed by setting the API version downlevel
export DOCKER_API_VERSION=1.39

docker push ${REGISTRY}/${IMAGE}:${VERSION}
