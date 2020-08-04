#!/bin/bash
#
# Copyright (c) 2020 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)
#

if [ -z "$1" ]
then
    echo "No work directory supplied"
    exit 1
fi

# Start the server
echo -n `date`
echo " Starting the server"
rm /tmp/server.log /tmp/server-stdout.log 2>/dev/null
IntegrationServer -w $1 --event-log /tmp/server.log > /tmp/server-stdout.log 2>&1 &

# Wait for it to finish initialising
counter=120
echo -n `date`
echo " Polling (for up to two minutes) for server startup to complete"
while [ "$counter" != "0" ]; do
    # Look for the startup finished message:
    # 2019-04-04 08:46:39.205168Z: [Thread 10860] (Msg 1/1) BIP1991I: Integration server has finished initialization.
    grep -q "BIP1991" /tmp/server.log 2>/dev/null
    if [ "$?" != "0" ]; then
#        echo "Server not available"
        sleep 1
    else
        echo -n `date`
        echo " Server is available"
        counter=0
    fi
done

cat /tmp/server-stdout.log
