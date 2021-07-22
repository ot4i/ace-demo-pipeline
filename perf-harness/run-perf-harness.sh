#!/bin/bash
#
# Copyright (c) 2021 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)
#

./start-server.sh /home/aceuser/ace-server
if [ "$?" != "0" ]; then
    echo "server start failed; exiting"
    exit 1
fi
sleep 5
echo "Attempting to call the service"

curl -i http://localhost:7800/tea/index/0 > /tmp/curl.out 2>/dev/null

echo Service returned:
cat /tmp/curl.out
echo

echo "Killing server"
ps -ef 
ps -ef | grep IntegrationServer | cut -c8-15 
ps -ef | grep IntegrationServer | cut -c8-15 | xargs kill -9 

grep -q "200 OK" /tmp/curl.out
if [ "$?" != "0" ]; then
    echo "testing failed"
    exit 1
else
    echo "testing passed"
    exit 0
fi
