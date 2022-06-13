# Cloud resources for pipeline use (in progress)

Need an IBM ID and then cloud registration at https://cloud.ibm.com/registration

The IBM Cloud tools should be available; installing them locally is one way to achieve this, following
the instructions at https://cloud.ibm.com/docs/cli?topic=cli-getting-started to install the ibmcloud
command and plugins. 

Tekton can be run from a dashboard or from the command line; the command is available from https://github.com/tektoncd/cli and
can be installed locally.

## API keys for command-line and Tekton builds

Need to create an API key: from the "Manage" menu at the top of the IBM Cloud dashboard, choose "Access (IAM)" and 
then "API keys" on the left. This key is used for login from local commands, Tekton builds, and container image
registry access.

## Kubernetes

Create a cluster called aceCluster by using the IBM Cloud dashboard: select "Kubernetes" on the left-side navigation 
bar (accessible via the hamburger icon at the top left), and then select "Create cluster" on the resulting Kubernetes 
screen.

The cluster may take a few minutes to provision. After the cluster has been created, then it should be possible
to login to ibmcloud and then access the cluster:
```
ibmcloud login -a cloud.ibm.com -r us-south --apikey <api key>
ibmcloud ks cluster config --cluster aceCluster
```

## Docker registry

Create a registry (under "Container Registry" on the IBM Cloud dashboard), then create a namespace 
with a unique name to store the images used in the demo. This demo has "us.icr.io/ace-registry" set as the 
default which means that "ace-registry" is already in use and another name must be chosen.

The various pipeline-run files in the tekton directories (ace-pipeline-run.yaml,
minimal-image-build/ace-minimal-image-pipeline-run.yaml, etc) need to be updated with the registry information,
otherwise permissions-related errors will occur.

To enable pipeline access to the registry, assign the API key (see above) as a "secret text" credential in 
Tekton called "regcred" for use in pushing and pulling container images:
```
kubectl create secret docker-registry regcred --docker-server=us.icr.io --docker-username=iamapikey --docker-password=<your-api-key>
```

## DB2 on Cloud

Create a DB2 instance via "Create resource" on the IBM Cloud dashboard; create credentials and add them to the Kubernetes cluster as "jdbc-secret" like this:
```
kubectl create secret generic jdbc-secret --from-literal=USERID='blah' --from-literal=PASSWORD='blah' --from-literal=databaseName='BLUDB' --from-literal=serverName='824dfd4d-99de-440d-9991-629c01b3832d.bs2io90l08kqb1od8lcg.databases.appdomain.cloud' --from-literal=portNumber='30119' 
```
with the obvious replacements.
