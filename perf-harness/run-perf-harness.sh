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
grep -q "200 OK" /tmp/curl.out
if [ "$?" != "0" ]; then
    echo "initial test failed!"
    exit 1
else
    echo "initial test succeeded"
fi

echo "Running perf harrness"

# This is set to a single thread because we're running on a Developer build which limits the number
# of messages per second to 1 . . . 
java -ms512M -mx512M -cp ./perfharness.jar JMSPerfHarness -tc http.HTTPRequestor -nt 1 -ss 5 -sc BasicStats -wi 10 -to 30000 -rl 30 -ws 1 -dn 1 -rb 131072 -jh localhost -jp 7800 -ot GET -ur "tea/index/0"

