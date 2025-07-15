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

For CP4i users, or plain Kubernetes users running the plain `ace` image 
(see [ACE containers: choosing a base image](https://community.ibm.com/community/user/integration/blogs/trevor-dolby/2024/02/05/ace-containers-choosing-a-base-image) 
for more information on the difference), an IBM Entitlement Key will be needed in order to access 
images from cp.icr.io; see [https://myibm.ibm.com/products-services/containerlibrary](https://myibm.ibm.com/products-services/containerlibrary)
to access the key.

Note that the `ace-minimal` image can be built from the (free) ACE installation package without
requiring an IBM Entitlement Key; see [https://github.com/ot4i/ace-docker/tree/main/experimental](https://github.com/ot4i/ace-docker/tree/main/experimental)
for the various images that can be built using Docker commands, and the [minimal-image-build README](/tekton/minimal-image-build/README.md) 
for details on how to build it using Tekton.

## DB2 on Cloud

To access the IBM cloud, an IBM ID is required and then cloud registration at https://cloud.ibm.com/registration

Create a DB2 instance via "Create resource" on the IBM Cloud dashboard; create credentials and add them to the Kubernetes cluster as "jdbc-secret" like this:
```
kubectl create secret generic jdbc-secret --from-literal=USERID='blah' --from-literal=PASSWORD='blah' --from-literal=databaseName='BLUDB' --from-literal=serverName='9938aec0-8105-433e-8bf9-0fbb7e483086.c1ogj3sd0tgtu0lqde00.databases.appdomain.cloud' --from-literal=portNumber='32459' 
```
with the obvious replacements.
