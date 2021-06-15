# Cloud resources for pipeline use (in progress)

Need an IBM ID and then cloud registration at https://cloud.ibm.com/registration

## Kubernetes

Create a cluster called aceCluster; this may take a few minutes to provision.

```
ibmcloud login -a cloud.ibm.com -r us-south -g default --apikey @~/tmp/ci-ibmcloud.txt
ibmcloud ks cluster config --cluster aceCluster
```

## Docker registry

Create a registry, then update scripts/preprod-bar-build.sh and scripts/preprod-deploy-and-test.sh:scripts/preprod-bar-build.sh to use it; note that the registry login may be region-sensitive and so the region parameter on "ibmcloud login" may need to changed as well.

Need to create a namespace for use with the us.icr.io container registry (for whichever region is chosen)

## DB2 on Cloud

Create a DB2 instance via "Create resource" on the IBM Cloud dashboard; create credentials and add them to the Kubernetes cluster as "jdbc-secret" like this:
```
kubectl create secret generic jdbc-secret --from-literal=USERID='blah' --from-literal=PASSWORD='blah' --from-literal=databaseName='BLUDB' --from-literal=serverName='dashdb-txn-sbox-yp-lon02-02.services.eu-gb.bluemix.net' --from-literal=portNumber='50000' 
```
with the obvious replacements.

## API keys for builds (via Jenkins)

Need to create an API key: from the "Manage" menu at the top of the IBM Cloud dashboard, choose "Access (IAM)" and then "API keys" on the left. Create a key, and then assign it as a "secret text" credential in Jenkins called IBMCLOUD_APIKEY
