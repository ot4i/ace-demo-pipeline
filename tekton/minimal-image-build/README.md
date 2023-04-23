# Tekton builds of pre-req images

Used to build images that can then be used to build and run ACE applications.

![Image build overview](ace-demo-pipeline-tekton-2.png)

## Getting started

 Most of the specific registry names need to be customised: us.icr.io may not be the right region, for example, and us.icr.io/ace-containers 
is unlikely to be writable. Creating registries and so on (though essential) is beyond the scope of this document, but customisation of
the artifacts in this repo (such as ace-minimal-build-image-pipeline.yaml) will almost certainly be necessary. Note that on Windows, kubectl
sometimes complains about not being able to validate files; using --validate=false appears to eliminate the issue without causing problems.

 The Tekton pipeline relies on docker credentials being provided for Kaniko to use when pushing the built image, and these credentials
must be associated with the service account for the pipeline. If this has not already been done elsewhere, then create as follows, with
appropriate changes for a fork of this repo:
```
kubectl create secret docker-registry regcred --docker-server=us.icr.io --docker-username=iamapikey --docker-password=<your-api-key>
kubectl apply -f tekton/service-account.yaml
```
The service account also has the ability to create services, deployments, etc, which are necessary for running the service. Note that
Windows kubectl seems to need the `--docker-email` parameter also, but the value can be anything.

## Setting the correct product version

The aceDownloadUrl value in ace-minimal-image-pipeline-run.yaml is likely to need updating, either to another version
in the same server directory (if available) or else to an ACE developer edition URL from the IBM website. In the latter
case, start at https://www.ibm.com/docs/en/app-connect/12.0?topic=enterprise-download-ace-developer-edition-get-started
and proceed through the pages until the main download page with a link: 

![download page](ace-dev-edition-download.png)

The link is likely to be of the form
```
https://iwm.dhe.ibm.com/sdfdl/v2/regs2/mbford/Xa.2/Xb.WJL1cUPI9gANEhP8GuPD_qX1rj6x5R4yTUM7s_C2ue8/Xc.12.0.8.0-ACE-LINUX64-DEVELOPER.tar.gz/Xd./Xf.LpR.D1vk/Xg.12164875/Xi.swg-wmbfd/XY.regsrvs/XZ.pPVETUejcqPsVfDVKbdNu6IRpo4TkyKu/12.0.8.0-ACE-LINUX64-DEVELOPER.tar.gz
```
Copy that link into the aceDownloadUrl parameter, adjusting the version numbers in the other files as needed.

## Running the pipeline

Setting up the pipeline requires Tekton to be installed (which may already have happend via OpenShift operators, in which case
skip the first line), tasks to be created, and the pipeline itself to be configured. The following commands build the ace-minimal
image and push it to the registry:
```
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply -f tekton/minimal-image-build/01-ace-minimal-image-build-and-push-task.yaml
kubectl apply -f tekton/minimal-image-build/ace-minimal-image-pipeline.yaml
kubectl apply -f tekton/minimal-image-build/ace-minimal-image-pipeline-run.yaml
tkn pipelinerun logs ace-minimal-image-pipeline-run-1 -f
```

Once that has been built, the ace-minimal-build image can be built as follows:
```
kubectl apply -f tekton/minimal-image-build/02-ace-minimal-build-image-build-and-push-task.yaml
kubectl apply -f tekton/minimal-image-build/ace-minimal-build-image-pipeline.yaml
kubectl apply -f tekton/minimal-image-build/ace-minimal-build-image-pipeline-run.yaml
tkn pipelinerun logs ace-minimal-build-image-pipeline-run-1 -f
```

## Issues with Kube nodes and Tekton

In certain cases, the images present in the repository cannot be "seen" by the Tekton pipeline task steps, for
unclear but credential-related reasons. Starting pods that use the images appears to force the pull to the worker
node, and this can be done as follows:
```
kubectl delete pod force-pull
kubectl apply -f tekton/force-pull-of-images.yaml
```

## OpenShift

The majority of steps are the same, but the registry authentication is a little different; assuming a session logged in as kubeadmin, it would look as follows:
```
kubectl create secret docker-registry regcred --docker-server=image-registry.openshift-image-registry.svc.cluster.local:5000 --docker-username=kubeadmin --docker-password=$(oc whoami -t)
```
Note that the actual password itself (as opposed to the hash provided by "oc whoami -t") does not work for registry authentication for some reason.

After that, the pipeline runs would be
```
kubectl apply -f tekton/minimal-image-build/os/ace-minimal-image-pipeline-run.yaml
kubectl apply -f tekton/minimal-image-build/os/ace-minimal-build-image-pipeline-run.yaml
```
to pick up the correct registry default.
