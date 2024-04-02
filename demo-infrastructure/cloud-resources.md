# Cloud resources for pipeline use (changed from previous iterations of the pipeline)

The IBM Kubernetes Service no longer offers the "free tier" that was used in prior versions
of this repo, and so the free options available are now [Minikube](https://minikube.sigs.k8s.io/docs/) 
(free to install locally) and [RedHat Single-Node OpenShift](https://www.redhat.com/en/blog/meet-single-node-openshift-our-smallest-openshift-footprint-edge-architectures)
(45-day trial installation). Both of these have been tested (including CP4i on OpenShift) but
the Tekton pipeline is generic enough that it should work with other Kubernetes providers with
only minimal modifications.

## Tekton interactions

For plain Kubernetes users, Tekton can be run from a dashboard or from the command line; 
the command is available from https://github.com/tektoncd/cli and can be installed locally.
OpenShift users should install the Red Hat OpenShift Pipelines operator, as this includes
Tekton and provides an integrated pipeline UI.

For Tekton dashboard users, the [Tekton dashboard docs](https://tekton.dev/docs/dashboard/install/#using-kubectl-port-forward) 
describe a port-forwarding way to access the dahsboard from outside the cluster, which may
be helpful.

## Docker registry

The IBM Cloud container registry does still have a free tier, but pull bandwidth is limited to
5GB a month per region so this may not be a good option for clusters running outside IBM Cloud. 

Both Minikube and OpenShift can run container registries within the cluster, and this is 
likely to be the best way to run simple pipeline experiments. The `registry` addon for Minikube
(plus some additional configuration to enable insecure access) can be enabled during cluster 
creation, and the OpenShift container registry can be enabled for single-node clusters by 
following [https://docs.openshift.com/container-platform/4.14/registry/configuring_registry_storage/configuring-registry-storage-baremetal.html](https://docs.openshift.com/container-platform/4.14/registry/configuring_registry_storage/configuring-registry-storage-baremetal.html)
if it is not already enabled.

External registries can also be used, including Docker hub and RedHat quay.io. Docker hub
has stricter rate limits at the time of writing, and repeated pipeline runs could hit those
limits in some cases. Use of a local registry is advised if possible, and if the pipeline
is run in a non-IBM cloud then using a registry associated with that cloud would be best.

Note that the minikube registry does not have security enabled by default, and so there is
no username/password combination to put in a `docker-registry` secret; dummy values can be
used instead to populate the (required) "regcred" secret:
```
kubectl create secret docker-registry regcred --docker-server=us.icr.io --docker-username=dummy --docker-password=dummy
```

For other registries, the credentials should be the same ones that would be used when running
`docker login`. For single-node OpenShift out-of-the-box, this can mean using the temporary 
admin credentials via `oc whoami -t`:
```
kubectl create secret docker-registry regcred --docker-server=image-registry.openshift-image-registry.svc.cluster.local:5000 --docker-username=kubeadmin --docker-password=$(oc whoami -t)
```


## DB2 on Cloud

To access the IBM cloud, an IBM ID is required and then cloud registration at https://cloud.ibm.com/registration

Create a DB2 instance via "Create resource" on the IBM Cloud dashboard; create credentials and add them to the Kubernetes cluster as "jdbc-secret" like this:
```
kubectl create secret generic jdbc-secret --from-literal=USERID='blah' --from-literal=PASSWORD='blah' --from-literal=databaseName='BLUDB' --from-literal=serverName='19af6446-6171-4641-8aba-9dcff8e1b6ff.c1ogj3sd0tgtu0lqde00.databases.appdomain.cloud' --from-literal=portNumber='30699' 
```
with the obvious replacements.
