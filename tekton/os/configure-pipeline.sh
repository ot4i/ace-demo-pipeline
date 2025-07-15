#!/bin/bash

# Assumes "oc login" with a current project of "ace"

# This one might fail
kubectl delete secret regcred

# Fail on error
set -e
kubectl create secret docker-registry regcred --docker-server=image-registry.openshift-image-registry.svc.cluster.local:5000 --docker-username=kubeadmin --docker-password=$(oc whoami -t)

# Print out commands once the secret has been created
set -x
kubectl apply -f tekton/os/service-account.yaml

# These are needed for Kaniko when running in a non-default namespace
kubectl apply -f tekton/os/ace-scc.yaml
oc adm policy add-scc-to-user ace-scc -z ace-tekton-service-account

kubectl apply -f tekton/minimal-image-build/01-ace-minimal-image-build-and-push-task.yaml
kubectl apply -f tekton/minimal-image-build/ace-minimal-image-pipeline.yaml
kubectl apply -f tekton/minimal-image-build/02-ace-minimal-build-image-build-and-push-task.yaml
kubectl apply -f tekton/minimal-image-build/ace-minimal-build-image-pipeline.yaml

kubectl apply -f tekton/10-maven-ace-build-task.yaml
kubectl apply -f tekton/20-deploy-to-cluster-task.yaml
kubectl apply -f tekton/21-knative-deploy-task.yaml
kubectl apply -f tekton/ace-pipeline.yaml
