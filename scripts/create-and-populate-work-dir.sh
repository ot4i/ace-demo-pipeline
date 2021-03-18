#!/bin/bash
#
# Copyright (c) 2020 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)
#

if [ ! -n "$1" ]
then
    echo "ERROR: No work directory provided - exiting"
    exit 1
fi
export WORKDIR=$1
# The rest of the arguments should be BAR file names
shift

echo "Create and populate work directory $WORKDIR with bars $*" 
rm -rf $WORKDIR
mqsicreateworkdir $WORKDIR
if [ "$?" != "0" ]; then
    echo "ERROR: create work dir failed; exiting"
    exit 1
fi
for barname in "$@"
do
    mqsibar -c -w $WORKDIR -a $barname
    if [ "$?" != "0" ]; then
	echo "ERROR: mqsibar failed for $barname; exiting"
	exit 1
    fi
done
