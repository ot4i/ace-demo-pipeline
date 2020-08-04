#!/bin/bash
#
# Copyright (c) 2020 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)
#

ibmcloud login -r us-south -g default --apikey $IBMCLOUD_APIKEY
ibmcloud ks cluster config -c aceCluster

kubectl delete service tea-service
kubectl delete deployment tea

# See init-creds.sh for more information; pre-req is of the form
#
# kubectl create secret generic jdbc-secret --from-literal=USERID='blah' --from-literal=PASSWORD='blah' --from-literal=databaseName='BLUDB' --from-literal=serverName='dashdb-txn-sbox-yp-lon02-02.services.eu-gb.bluemix.net' --from-literal=portNumber='50000' 

kubectl run tea --image uk.icr.io/ace-registry/tea:latest --port=7800 --overrides='{"apiVersion": "apps/v1", "spec": {"template": { "spec": { "volumes": [ { "name": "secret-volume-2", "secret": { "secretName": "jdbc-secret" } } ], "containers": [ { "name": "tea", "image": "uk.icr.io/ace-registry/tea:latest", "volumeMounts": [ { "name": "secret-volume-2", "mountPath": "/var/run/secrets/jdbc" } ] } ] } } } }'

kubectl expose deployment/tea --type=NodePort --port=7800 --target-port=7800 --name tea-service
ibmcloud ks workers --cluster aceCluster



kubectl get service tea-service
export PORT=`kubectl get service tea-service | tr ' ' '\n' | grep TCP | cut -c 6-10`
ibmcloud ks workers --cluster aceCluster
export HOST=`ibmcloud ks workers --cluster aceCluster | grep kube | cut -c55-72 | tr -d ' '`

echo URL is http://$HOST:$PORT/tea/index/0

echo "Waiting for the service to start"
sleep 15
echo "Attempting to call the service"

curl -i http://$HOST:$PORT/tea/index/0 > /tmp/curl.out 2>/dev/null

echo Service returned:
cat /tmp/curl.out
echo

grep -q "200 OK" /tmp/curl.out
if [ "$?" != "0" ]; then
    echo "Failed to get tea index 0"
    exit 1
fi


