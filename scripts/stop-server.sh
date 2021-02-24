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
echo " Killing the server"
ps -ef | grep IntegrationServer
ps -ef | grep IntegrationServer | grep $1 | cut -c8-16 | xargs kill -9 
