#!/bin/bash
#
# Copyright (c) 2020 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)
#

if [ -z "$1" ]
then
    echo "No directory name supplied"
    exit 1
fi

# This looks slightly odd, but for some reason with kaniko we end up with a userid that can't access /var/mqsi
# and so we redirect the product to the equivalent in the work directory
export MQSI_REGISTRY=/home/aceuser/ace-server/config

for filename in $1/*.bar; do
    [ -e "$filename" ] || continue
    echo "Deploying $filename"
    mqsibar -c -a $filename -w /home/aceuser/ace-server
done
