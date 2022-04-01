# Tekton pipeline

Used to run the pipeline stages via Tekton. Relies on the same IBM Cloud kubernetes cluster as before, with the JDBC
credentials having been set up, and can also be run using OpenShift Code-Ready Containers (tested on 1.27).

![Pipeline overview](../ace-demo-pipeline-tekton-1.png)

The tasks rely on several different containers:

- The Tekton git-init image to run the initial git clones.
- Kaniko for building the container images.
- The ace-minimal image for a small Alpine-based runtime container (~420MB, which fits into the IBM Cloud container registry
free tier limit of 512MB), and builder variant with Maven added in.  See https://github.com/tdolby-at-uk-ibm-com/ace-docker/tree/master/experimental/ace-minimal
for more details on the minimal image, and [minimal image build instructions](minimal-image-build/README.md) on how to build the various pre-req images.

For the initial testing, variants of ace-minimal:12.0.4.0-alpine have been pushed to tdolby/experimental on DockerHub, but this is not a
stable location, and the images should be rebuilt by anyone attempting to use this repo.

## Getting started

 Most of the specific registry names need to be customised: us.icr.io may not be the right region, for example, and us.icr.io/ace-registry 
is unlikely to be writable. Creating registries and so on (though essential) is beyond the scope of this document, but customisation of
the artifacts in this repo (such as ace-pipeline-run.yaml) will almost certainly be necessary.

 The Tekton pipeline relies on docker credentials being provided for Kaniko to use when pushing the built image, and these credentials
must be associated with the service account for the pipeline. If this has not already been done elsewhere, then create as follows, with
appropriate changes for a fork of this repo:
```
kubectl create secret docker-registry regcred --docker-server=us.icr.io --docker-username=iamapikey --docker-password=<your-api-key>
kubectl apply -f tekton/service-account.yaml
```
The service account also has the ability to create services, deployments, etc, which are necessary for running the service.

Setting up the pipeline requires Tekton to be installed, tasks to be created, and the pipeline itself to be configured:
```
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply -f tekton/10-maven-ace-build-task.yaml
kubectl apply -f tekton/20-deploy-to-cluster-task.yaml
kubectl apply -f tekton/ace-pipeline.yaml
```

Once that has been accomplished, the simplest way to run the pipeline is
```
kubectl apply -f tekton/ace-pipeline-run.yaml
tkn pipelinerun logs ace-pipeline-run-1 -f
```

and this should build the projects, run the unit tests, create a docker image, and then create a deployment that runs the application.

## How to know if the pipeline has succeeded

The end result should be a running container with the tea application deployed, listening for requests on /tea/index at the
appropriate host and port. An HTTP GET on http://containerHost:containerPort/tea/index/0 should return some JSON, though the 
name may be null if the database has no entry for id 0.

For the IBM Kubernetes Service, the public IP address of the worker node is the easiest way to access the service, but the host
is not published in the usual external IP field. To find the external IP, use IBM Cloud dashboard to view the "Worker nodes" 
tab information for the Kube cluster, where the "Public IP" contains the correct address. The port number can be found by querying
the Kubernetes tea-tekton-service either by using
```
kubectl get service tea-tekton-service
```
or by using the Kubernetes dashboard to view the service. These values can then be used to access the application.

Note that if errors of the form

```
BIP2230E: Error detected whilst processing a message in node 'gen.TeaRESTApplication.getIndex (Implementation).GetFromDB.Get DB record'.
BIP6233E: An error occurred in node: Broker 'integration_server'; Execution Group 'ace-server'; Message Flow 'gen.TeaRESTApplication';
Node 'getIndex (Implementation).GetFromDB.Get DB record'; Node Type 'GetIndex_JavaCompute There was a problem establishing a connection
to the given database URL: jdbc:db2://824dfd4d-99de-440d-9991-629c01b3832d.bs2io90l08kqb1od8lcg.databases.appdomain.cloud:30119/BLUDB:user=yyyyyyyy;password=xxxxxxxx;
Exception details: error message: [jcc][t4][2034][11148][3.71.22] Execution failed due to a distribution protocol error that caused deallocation of the conversation.
```
occur, then it is likely that the TEAJDBC policy is not configured to use SSL. Setting

```
<environmentParms>sslConnection=true</environmentParms>
```
in the policyxml should eliminate this error.

## Tekton dashboard

The Tekton dashboard (for non-OpenShift users) can be installed as follows:
```
kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml
```

By default, the Tekton dashboard is not accessible outside the cluster; assuming a secure host somewhere, the
dashboard HTTP port can be made available locally as follows:
```
kubectl --namespace tekton-pipelines port-forward --address 0.0.0.0 svc/tekton-dashboard 9097:9097
```

## OpenShift CRC

The majority of steps are the same, but the registry authentication is a little different; assuming a session logged in as kubeadmin, it would look as follows:
```
kubectl create secret docker-registry regcred --docker-server=image-registry.openshift-image-registry.svc:5000 --docker-username=kubeadmin --docker-password=$(oc whoami -t)
```
Note that the actual password itself (as opposed to the hash provided by "oc whoami -t") does not work for registry authentication for some reason.

After that, the pipeline run would be
```
kubectl apply -f tekton/os/ace-pipeline-run-crc.yaml
tkn pipelinerun logs ace-pipeline-run-1 -f
```
to pick up the correct registry default. The OpenShift Pipeline operator provides a web interface for the pipeline runs
also, which may be an easier way to view progress.

To enable external connectivity from within OpenShift to enable testing, run the following
```
kubectl apply -f tekton/os/tea-tekton-route.yaml
```
which will create a route at http://tea-route-default.apps-crc.testing (which can be changed in the yaml file).

Accessing http://tea-route-default.apps-crc.testing/tea/index/0 should result in the application running and showing
JSON result data.

## Possible enhancements

The pipeline should use a single git commit to ensure the two tasks are actually using the same source. Alternatively, PVCs could 
be used to share a workspace between the tasks, which at the moment use transient volumes to maintain state between the task steps 
but not between the tasks themselves.

The remaining docker images, git repo references, etc could be turned into parameters.
