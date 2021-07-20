# zLinux prototype

This directory contains the files used in getting the pipeline to run on a zLinux cluster.
Most of the files are shared, but some needed to be changed due to platform-specific issues.

## Changes

Main changes from the parent directory:

- Using Ubuntu instead of Alpine for ace-minimal. Alpine exists for s390x but the glibc binaries are not readily available, and the ACE product relies on glibc.
- ACE v12 on s390x does not ship with a JDK (has a JRE instead), so the IBM JDK needed to be downloaded for the builder image. The JDK is not needed for runtime.
- Kaniko releases do not appear to provide s390x images; https://github.com/GoogleContainerTools/kaniko/pull/1475 provides an intermediate image tag that works.

## Commands

Assuming the credentials have been set up as they would for other platforms, the minimal 
image needs to be built:

```
kubectl apply -f tekton/zLinux-prototype/01-ace-minimal-image-build-and-push-task.yaml
kubectl apply -f tekton/minimal-image-build/ace-minimal-image-pipeline.yaml
kubectl apply -f tekton/zLinux-prototype/ace-minimal-image-pipeline-run-zLinux.yaml
tkn pipelinerun logs ace-minimal-image-pipeline-run-1 -f
```

Once that has been built, the ace-minimal-build image can be built as follows:
```
kubectl apply -f tekton/zLinux-prototype/02-ace-minimal-build-image-build-and-push-task.yaml
kubectl apply -f tekton/minimal-image-build/ace-minimal-build-image-pipeline.yaml
kubectl apply -f tekton/minimal-image-build/os/ace-minimal-build-image-pipeline-run-crc.yaml
tkn pipelinerun logs ace-minimal-build-image-pipeline-run-1 -f
```

After the minimal and builder images have been successfully created, the main pipeline
can be run:
```
kubectl apply -f tekton/zLinux-prototype/10-maven-ace-build-task.yaml
kubectl apply -f tekton/20-deploy-to-cluster-task.yaml
kubectl apply -f tekton/ace-pipeline.yaml
kubectl apply -f tekton/os/ace-pipeline-run-crc.yaml
tkn pipelinerun logs ace-pipeline-run-1 -f
```

To enable external connectivity from within OpenShift to enable testing, adjust the 
hostname in the tea-tekton-route.yaml to match the cluster, and then run
```
kubectl apply -f tekton/zLinux-prototype/tea-tekton-route.yaml
```
which will create a route at http://tea-route-default.apps.acecc-shared-46-s390x.cp.fyre.ibm.com by 
default (the hostname should be changed  in the yaml file).

Accessing http://tea-route-default.apps.acecc-shared-46-s390x.cp.fyre.ibm.com/tea/index/0 should 
result in the application running and showing JSON result data.
