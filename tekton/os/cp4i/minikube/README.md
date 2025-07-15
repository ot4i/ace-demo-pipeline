# Minikube setup for CP4i

[Minikube](https://minikube.sigs.k8s.io/docs/) is used extensively for local Kubernetes testing
and there are quite a few guides on the Internet to explain how to set it up and configure it.

This directory contains the CP4i-specific Minikube information; see [/tekton/minikube/README.md](/tekton/minikube/README.md)
for plain Kubernetes. The same notes apply, along with the beginning of the setup.

The definitive instructions for installing the ACE operator on non-OpenShift can be found at [https://www.ibm.com/docs/en/app-connect/containers_cd?topic=connect-installing-uninstalling-kubernetes](https://www.ibm.com/docs/en/app-connect/containers_cd?topic=connect-installing-uninstalling-kubernetes)
and the summary below tries to reflect the current state of the instructions.

## Steps

```
minikube start --insecure-registry "192.168.0.0/16"
minikube addons enable dashboard
minikube addons enable registry
minikube addons enable metrics-server

ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ minikube ip
192.168.49.2

kubectl apply -f tekton/minikube/minikube-registry-nodeport.yaml

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml
kubectl get pods --namespace cert-manager
kubectl patch deployment \
  cert-manager \
  --namespace cert-manager  \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": [
  "--v=2",
  "--cluster-resource-namespace=$(POD_NAMESPACE)",
  "--leader-election-namespace=kube-system",
  "--enable-certificate-owner-ref"
]}]'

operator-sdk olm install

kubectl create namespace cp4i
kubectl apply -f tekton/os/cp4i/minikube/minikube-install-og.yaml
kubectl apply -f tekton/os/cp4i/minikube/minikube-install-catalog-source.yaml
kubectl get CatalogSources ibm-appconnect-catalog -n olm
kubectl create secret -n cp4i docker-registry ibm-entitlement-key --docker-username=cp --docker-password=IBMENTITLEMENTKEY --docker-server=cp.icr.io
kubectl apply -f tekton/os/cp4i/minikube/minikube-install-subscription.yaml

kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml
kubectl create secret -n cp4i docker-registry regcred --docker-server=us.icr.io --docker-username=notused --docker-password=notused
kubectl create secret -n cp4i generic jdbc-secret --from-literal=USERID='BLAH' --from-literal=PASSWORD='BLAH' --from-literal=databaseName='BLUDB' --from-literal=serverName='9938aec0-8105-433e-8bf9-0fbb7e483086.c1ogj3sd0tgtu0lqde00.databases.appdomain.cloud' --from-literal=portNumber='32459'

kubectl apply -f tekton/os/cp4i/service-account-cp4i.yaml

kubectl apply -f tekton/os/cp4i/12-ibmint-cp4i-build-task.yaml
kubectl apply -f tekton/os/cp4i/13-component-test-in-cp4i-task.yaml
kubectl apply -f tekton/os/cp4i/22-deploy-to-cp4i-task.yaml
kubectl apply -f tekton/os/cp4i/cp4i-pipeline.yaml
```

At this point, it should be possible to edit `tekton/os/cp4i/cp4i-pipeline-run.yaml` to reflect
the Minikube registry address and then run the pipeline as shown at [/tekton/os/cp4i/README.md#pipeline-setup-and-run](/tekton/os/cp4i/README.md#pipeline-setup-and-run)
with the main difference being the use of the Tekton dashboard to monitor the pipeline run
instead of using the RedHat OpenShift Pipelines UI.
