# Demo pipeline source-to-image build for OpenShift

A simple way to build and expose the demo application via OpenShift's application building technology. Relies 
on the s2i ACE images from https://github.com/tdolby-at-uk-ibm-com/ace-docker/tree/master/experimental/s2i which 
in turn depend on ace-full and ace-minimal in the peer directories in that repo.

Tested using CRC 1.21.0 with Windows Hyper-V.

## Getting Started

Credentials need to be created for the docker registry and also the DB2 instance used by the application (see [cloud resources description](../cloud-resources.md) for more info):

```
kubectl create secret docker-registry regcred --docker-server=image-registry.openshift-image-registry.svc:5000 --docker-username=kubeadmin --docker-password=$(oc whoami -t)
kubectl create secret generic jdbc-secret --from-literal=USERID='blah' --from-literal=PASSWORD='blah' --from-literal=databaseName='BLUDB' --from-literal=serverName='dashdb-txn-sbox-yp-lon02-02.services.eu-gb.bluemix.net' --from-literal=portNumber='50000' 
```
Once those are in place, then the template in this directory needs to be loaded into the cluster:
```
oc apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/master/s2i/tea-oc-hybrid-stibuild.json
```
and then a build can be kicked off:
```
oc new-app tea-application
```

## Cleaning up

Mostly for development use
```
oc delete route/tea-oc-route dc/tea-oc-deployment bc/tea-oc-build is/ace-s2i-imagestream is/tea-oc-imagestream svc/tea-oc-service
```
