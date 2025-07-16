# Serverless with Knative

Knative serving of the Tea application; relies on the main pipeline having been
run already, and Knative Serving being installed. See https://knative.dev/docs/serving/
for more details on the latter, but for OpenShift users installing the RedHat
Serverless operator is the simplest way to achieve the goal.

## Permissions

The knative-service-account.yaml extends the existing pipeline service account to
allow for Knative service creation. Modify based on organisational needs; the default
is to assign knative-serving-admin which may be more than desired.

```
kubectl apply -f extensions/serverless/knative-service-account.yaml
```

## Commands

Once the permissions have been updated, the task can be created and run:
```
kubectl apply -f tekton/21-knative-deploy-task.yaml
kubectl apply -f tekton/knative-deploy-taskrun.yaml
tkn taskrun logs knative-deploy-taskrun-1 -f
```

This should create a working Knative service deployment using the spec in
the [tea-tekton-knative-service.yaml](tea-tekton-knative-service.yaml) file
in this directory.

Assuming the use of OpenShift, the service should be accessible at a hostname
such as tea-tekton-knative-default.acecc-shared-46-s390x.cp.fyre.ibm.com or
similar; when using CodeReady Containers, the URL http://tea-tekton-knative-default.apps-crc.testing/tea/index/1
should result in the application running and showing JSON result data.

