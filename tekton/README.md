# Tekton pipeline

Used to run the pipeline stages via Tekton. Relies on the same IBM Cloud kubernetes cluster as before, with the JDBC
credentials having been set up, and can also be run using OpenShift Code-Ready Containers (tested on 1.21).

![Pipeline overview](../ace-demo-pipeline-tekton-1.png)

The tasks rely on several different containers:

- The Tekton git-init image to run the initial git clones.
- Kaniko for building the container images.
- The ace-minimal image for a small Alpine-based runtime container (~420MB, which fits into the IBM Cloud container registry
free tier limit of 512MB), and builder variant with Maven added in.  See https://github.com/tdolby-at-uk-ibm-com/ace-docker/tree/master/experimental/ace-minimal
for more details on the minimal image, and [minimal image build instructions](README-image-build.md) on how to build the various pre-req images.

For the initial testing, variants of ace-minimal:12.0.1.0-alpine have been pushed to tdolby/experimental on DockerHub, but this is not a
stable location, and the images should be rebuilt by anyone attempting to use this repo.

## Getting started

 Most of the specific registry names need to be customised: us.icr.io may not be the right region, for example, and us.icr.io/ace-registry 
is unlikely to be writable. Creating registries and so on (though essential) is beyond the scope of this document, but customisation of
the artifacts in this repo (such as ace-pipeline-run.yaml) will almost certainly be necessary.

 The Tekton pipeline relies on docker credentials being provided for Kaniko to use when pushing the built image, and these credentials
must be associated with the service account for the pipeline. Create as follows, with appropriate changes for a fork of this repo:
```
kubectl create secret docker-registry regcred --docker-server=us.icr.io --docker-username=iamapikey --docker-password=<your-api-key>
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/master/tekton/service-account.yaml
```
The service account also has the ability to create services, deployments, etc, which are necessary for running the service.

Setting up the pipeline requires Tekton to be installed, tasks to be created, and the pipeline itself to be configured:
```
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/master/tekton/10-maven-ace-build-task.yaml
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/master/tekton/20-deploy-to-cluster-task.yaml
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/master/tekton/ace-pipeline.yaml
```

Once that has been accomplished, the simplest way to run the pipeline is
```
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/master/tekton/ace-pipeline-run.yaml
tkn pipelinerun logs ace-pipeline-run-1 -f
```

and this should build the projects, run the unit tests, create a docker image, and then create a deployment that runs the application.

## OpenShift CRC

The majority of steps are the same, but the registry authentication is a little different; assuming a session logged in as kubeadmin, it would look as follows:
```
kubectl create secret docker-registry regcred --docker-server=image-registry.openshift-image-registry.svc:5000 --docker-username=kubeadmin --docker-password=$(oc whoami -t)
```
Note that the actual password itself (as opposed to the hash provided by "oc whoami -t") does not work for registry authentication for some reason.

After that, the pipeline run would be
```
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/master/tekton/ace-pipeline-run-crc.yaml
tkn pipelinerun logs ace-pipeline-run-1 -f
```
to pick up the correct registry default.

## Possible enhancements

The pipeline should use a single git commit to ensure the two tasks are actually using the same source. Alternatively, PVCs could 
be used to share a workspace between the tasks, which at the moment use transient volumes to maintain state between the task steps 
but not between the tasks themselves.

The remaining docker images, git repo references, etc could be turned into parameters.
