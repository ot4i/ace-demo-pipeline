# Minikube setup 

[Minikube](https://minikube.sigs.k8s.io/docs/) is used extensively for local Kubernetes testing
and there are quite a few guides on the Internet to explain how to set it up and configure it.
This README describes one example of using minikube v1.32.0 on Ubuntu 22.04 with the demo pipeline.

Points to note:
- The IP address range in this case was 192.168.x.y but this may vary. The `minikube ip` command
  should provide the correct address, which then can be used to determine the correct subnet 
  value for the `--insecure-registry` parameter. The addresses appear to be the same for a given
  machine, so running `minikube start` followed by `minikube ip` to find the IP address followed
  by `minikube stop` and `minikube delete` should provide the information necessary for the "real"
  startup command line.
- This example uses either `ace-minimal` and `ace-minimal-build` or the `ace` image instead.
  Note that the `ace` image should be copied locally for best performance as shown below.
- The ingress addon is optional, and container testing can be achieved by port forwarding instead.
- ACE-as-a-Service builds are also possible, and follow the usual pattern described in [/tekton/README.md](/tekton/README.md)

See [Walkthrough](#walkthrough) for a full example including Knative.

## Steps

```
minikube start --insecure-registry "192.168.0.0/16"
minikube addons enable dashboard
minikube addons enable registry
minikube addons enable metrics-server

ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ minikube ip
192.168.49.2

kubectl apply -f tekton/minikube/minikube-registry-nodeport.yaml
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml
kubectl create secret docker-registry regcred --docker-server=us.icr.io --docker-username=notused --docker-password=notused
kubectl create secret generic jdbc-secret --from-literal=USERID='BLAH' --from-literal=PASSWORD='BLAH' --from-literal=databaseName='BLUDB' --from-literal=serverName='9938aec0-8105-433e-8bf9-0fbb7e483086.c1ogj3sd0tgtu0lqde00.databases.appdomain.cloud' --from-literal=portNumber='32459'

kubectl apply -f tekton/service-account.yaml
```

For the `ace` image (following https://www.ibm.com/docs/en/app-connect/containers_cd?topic=resources-obtaining-applying-your-entitlement-key):
```
kubectl create secret docker-registry ibm-entitlement-key --docker-username=cp --docker-password=myEntitlementKey --docker-server=cp.icr.io
minikube ssh
docker login cp.icr.io -u cp -p ibmEntitlementKey
docker pull cp.icr.io/cp/appc/ace:13.0.4.0-r1
docker tag cp.icr.io/cp/appc/ace:13.0.4.0-r1 192.168.49.2:5000/default/ace:13.0.4.0-r1
docker push 192.168.49.2:5000/default/ace:13.0.4.0-r1
```

For `ace-minimal` and `ace-minimal-build`, update the `aceDownloadUrl` parameter in
tekton/minimal-image-build/ace-minimal-build-image-pipeline-run.yaml to a valid download URL
(see [setting-the-correct-product-version](/tekton/minimal-image-build/README.md#setting-the-correct-product-version)
for details) and then run:
```
kubectl apply -f tekton/minimal-image-build/01-ace-minimal-image-build-and-push-task.yaml
kubectl apply -f tekton/minimal-image-build/02-ace-minimal-build-image-build-and-push-task.yaml
kubectl apply -f tekton/minimal-image-build/ace-minimal-image-pipeline.yaml
kubectl apply -f tekton/minimal-image-build/ace-minimal-build-image-pipeline.yaml

kubectl create -f tekton/minimal-image-build/ace-minimal-build-image-pipeline-run.yaml
tkn pipelinerun logs -L -f
```

Building and deploying the application:
```
kubectl apply -f tekton/10-ibmint-ace-build-task.yaml
kubectl apply -f tekton/20-deploy-to-cluster-task.yaml
kubectl apply -f tekton/21-knative-deploy-task.yaml
kubectl apply -f tekton/ace-pipeline.yaml

kubectl create -f tekton/ace-pipeline-run.yaml
tkn pipelinerun logs -L -f

minikube addons enable ingress
kubectl apply -f tekton/minikube/tea-tekton-minikube-ingress.yaml
```
The application should now be available and can be tested with `curl http://192.168.49.2/tea/index/2` to GET index 2.


## Knative setup:

```
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.12.1/serving-crds.yaml
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.11.6/eventing-crds.yaml

kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.12.1/serving-core.yaml

kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v1.12.1/kourier.yaml

kubectl patch configmap/config-network -n knative-serving --type merge -p '{"data":{"ingress.class":"kourier.ingress.networking.knative.dev"}}'

kubectl apply -f https://projectcontour.io/quickstart/contour.yaml

cat <<EOF | kubectl apply -n kourier-system -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kourier-ingress
  namespace: kourier-system
spec:
  rules:
  - http:
     paths:
       - path: /
         pathType: Prefix
         backend:
           service:
             name: kourier
             port:
               number: 80
EOF

export ksvc_domain="\"data\":{\""$(minikube ip)".nip.io\": \"\"}"
kubectl patch configmap/config-domain -n knative-serving --type merge  -p "{$ksvc_domain}"

cat extensions/serverless/tea-tekton-knative-service.yaml | sed 's/DOCKER_REGISTRY/192.168.49.2:5000\/default/g' | sed 's/IMAGE_TAG/20240408183942-f07980e/g' |  kubectl apply -f -

curl -LO https://github.com/knative/client/releases/download/knative-v1.11.2/kn-linux-amd64
```

## Walkthrough

Passwords redacted:
```
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ minikube start --insecure-registry "192.168.0.0/16"
😄  minikube v1.32.0 on Ubuntu 22.04
✨  Automatically selected the docker driver. Other choices: kvm2, qemu2, ssh
📌  Using Docker driver with root privileges
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
    > gcr.io/k8s-minikube/kicbase...:  453.90 MiB / 453.90 MiB  100.00% 40.66 M
🔥  Creating docker container (CPUs=2, Memory=3900MB) ...
🐳  Preparing Kubernetes v1.28.3 on Docker 24.0.7 ...
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔗  Configuring bridge CNI (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ minikube addons enable dashboard
💡  dashboard is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.
You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS
    ▪ Using image docker.io/kubernetesui/dashboard:v2.7.0
    ▪ Using image docker.io/kubernetesui/metrics-scraper:v1.0.8
💡  Some dashboard features require the metrics-server addon. To enable all features please run:

        minikube addons enable metrics-server


🌟  The 'dashboard' addon is enabled
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ minikube addons enable registry
💡  registry is an addon maintained by minikube. For any concerns contact minikube on GitHub.
You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS
    ▪ Using image docker.io/registry:2.8.3
    ▪ Using image gcr.io/k8s-minikube/kube-registry-proxy:0.0.5
🔎  Verifying registry addon...
🌟  The 'registry' addon is enabled
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ minikube addons enable metrics-server
💡  metrics-server is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.
You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS
    ▪ Using image registry.k8s.io/metrics-server/metrics-server:v0.6.4
🌟  The 'metrics-server' addon is enabled
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ minikube ip
192.168.49.2
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply -f tekton/minikube/minikube-registry-nodeport.yaml
service/registry-nodeport created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ minikube ssh
docker@minikube:~$ docker login cp.icr.io -u cp -p ibmEntitlementKey
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
WARNING! Your password will be stored unencrypted in /home/docker/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
docker@minikube:~$ docker pull cp.icr.io/cp/appc/ace:12.0.11.0-r1
12.0.11.0-r1: Pulling from cp/appc/ace
a032f50e22ae: Pull complete
1bb268c9da71: Pull complete
a8313fdaaeb2: Pull complete
2aa0417eb4e3: Pull complete
446d1d900c62: Pull complete
Digest: sha256:2a3ba6902daf785b7ae435a6aaa6f7018e0b9dcfec8c0d1a5e82107b01e7394c
Status: Downloaded newer image for cp.icr.io/cp/appc/ace:12.0.11.0-r1
cp.icr.io/cp/appc/ace:12.0.11.0-r1
docker@minikube:~$ docker tag cp.icr.io/cp/appc/ace:12.0.11.0-r1 192.168.49.2:5000/default/ace:12.0.11.0-r1
docker@minikube:~$ docker push 192.168.49.2:5000/default/ace:12.0.11.0-r1
The push refers to repository [192.168.49.2:5000/default/ace]
ece30248c995: Pushed
a2240a6f3243: Pushed
eb39a818d785: Pushed
ec6dd3599c39: Pushed
80c0d7946d02: Pushed
12.0.11.0-r1: digest: sha256:6261af08295ff3ea9126c6e1126619522476ca794ec202fbc596fb1ccf66a5a1 size: 1376
docker@minikube:~$ exit
logout
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
namespace/tekton-pipelines created
clusterrole.rbac.authorization.k8s.io/tekton-pipelines-controller-cluster-access created
clusterrole.rbac.authorization.k8s.io/tekton-pipelines-controller-tenant-access created
clusterrole.rbac.authorization.k8s.io/tekton-pipelines-webhook-cluster-access created
clusterrole.rbac.authorization.k8s.io/tekton-events-controller-cluster-access created
role.rbac.authorization.k8s.io/tekton-pipelines-controller created
role.rbac.authorization.k8s.io/tekton-pipelines-webhook created
role.rbac.authorization.k8s.io/tekton-pipelines-events-controller created
role.rbac.authorization.k8s.io/tekton-pipelines-leader-election created
role.rbac.authorization.k8s.io/tekton-pipelines-info created
serviceaccount/tekton-pipelines-controller created
serviceaccount/tekton-pipelines-webhook created
serviceaccount/tekton-events-controller created
clusterrolebinding.rbac.authorization.k8s.io/tekton-pipelines-controller-cluster-access created
clusterrolebinding.rbac.authorization.k8s.io/tekton-pipelines-controller-tenant-access created
clusterrolebinding.rbac.authorization.k8s.io/tekton-pipelines-webhook-cluster-access created
clusterrolebinding.rbac.authorization.k8s.io/tekton-events-controller-cluster-access created
rolebinding.rbac.authorization.k8s.io/tekton-pipelines-controller created
rolebinding.rbac.authorization.k8s.io/tekton-pipelines-webhook created
rolebinding.rbac.authorization.k8s.io/tekton-pipelines-controller-leaderelection created
rolebinding.rbac.authorization.k8s.io/tekton-pipelines-webhook-leaderelection created
rolebinding.rbac.authorization.k8s.io/tekton-pipelines-info created
rolebinding.rbac.authorization.k8s.io/tekton-pipelines-events-controller created
rolebinding.rbac.authorization.k8s.io/tekton-events-controller-leaderelection created
customresourcedefinition.apiextensions.k8s.io/clustertasks.tekton.dev created
customresourcedefinition.apiextensions.k8s.io/customruns.tekton.dev created
customresourcedefinition.apiextensions.k8s.io/pipelines.tekton.dev created
customresourcedefinition.apiextensions.k8s.io/pipelineruns.tekton.dev created
customresourcedefinition.apiextensions.k8s.io/resolutionrequests.resolution.tekton.dev created
customresourcedefinition.apiextensions.k8s.io/stepactions.tekton.dev created
customresourcedefinition.apiextensions.k8s.io/tasks.tekton.dev created
customresourcedefinition.apiextensions.k8s.io/taskruns.tekton.dev created
customresourcedefinition.apiextensions.k8s.io/verificationpolicies.tekton.dev created
secret/webhook-certs created
validatingwebhookconfiguration.admissionregistration.k8s.io/validation.webhook.pipeline.tekton.dev created
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.pipeline.tekton.dev created
validatingwebhookconfiguration.admissionregistration.k8s.io/config.webhook.pipeline.tekton.dev created
clusterrole.rbac.authorization.k8s.io/tekton-aggregate-edit created
clusterrole.rbac.authorization.k8s.io/tekton-aggregate-view created
configmap/config-defaults created
configmap/config-events created
configmap/feature-flags created
configmap/pipelines-info created
configmap/config-leader-election-controller created
configmap/config-leader-election-events created
configmap/config-leader-election-webhook created
configmap/config-logging created
configmap/config-observability created
configmap/config-registry-cert created
configmap/config-spire created
configmap/config-tracing created
deployment.apps/tekton-pipelines-controller created
service/tekton-pipelines-controller created
deployment.apps/tekton-events-controller created
service/tekton-events-controller created
namespace/tekton-pipelines-resolvers created
clusterrole.rbac.authorization.k8s.io/tekton-pipelines-resolvers-resolution-request-updates created
role.rbac.authorization.k8s.io/tekton-pipelines-resolvers-namespace-rbac created
serviceaccount/tekton-pipelines-resolvers created
clusterrolebinding.rbac.authorization.k8s.io/tekton-pipelines-resolvers created
rolebinding.rbac.authorization.k8s.io/tekton-pipelines-resolvers-namespace-rbac created
configmap/bundleresolver-config created
configmap/cluster-resolver-config created
configmap/resolvers-feature-flags created
configmap/config-leader-election-resolvers created
configmap/config-logging created
configmap/config-observability created
configmap/git-resolver-config created
configmap/http-resolver-config created
configmap/hubresolver-config created
deployment.apps/tekton-pipelines-remote-resolvers created
service/tekton-pipelines-remote-resolvers created
horizontalpodautoscaler.autoscaling/tekton-pipelines-webhook created
deployment.apps/tekton-pipelines-webhook created
service/tekton-pipelines-webhook created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml
customresourcedefinition.apiextensions.k8s.io/extensions.dashboard.tekton.dev created
serviceaccount/tekton-dashboard created
role.rbac.authorization.k8s.io/tekton-dashboard-info created
clusterrole.rbac.authorization.k8s.io/tekton-dashboard-backend created
clusterrole.rbac.authorization.k8s.io/tekton-dashboard-tenant created
rolebinding.rbac.authorization.k8s.io/tekton-dashboard-info created
clusterrolebinding.rbac.authorization.k8s.io/tekton-dashboard-backend created
configmap/dashboard-info created
service/tekton-dashboard created
deployment.apps/tekton-dashboard created
clusterrolebinding.rbac.authorization.k8s.io/tekton-dashboard-tenant created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl create secret docker-registry regcred --docker-server=us.icr.io --docker-username=notused --docker-password=notused
secret/regcred created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl create secret generic jdbc-secret --from-literal=USERID='BLAH' --from-literal=PASSWORD='BLAH' --from-literal=databaseName='BLUDB' --from-literal=serverName='9938aec0-8105-433e-8bf9-0fbb7e483086.c1ogj3sd0tgtu0lqde00.databases.appdomain.cloud' --from-literal=portNumber='32459'
secret/jdbc-secret created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply -f tekton/service-account.yaml
serviceaccount/ace-tekton-service-account created
role.rbac.authorization.k8s.io/pipeline-role created
rolebinding.rbac.authorization.k8s.io/pipeline-role-binding created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply -f tekton/minimal-image-build/01-ace-minimal-image-build-and-push-task.yaml
task.tekton.dev/ace-minimal-image-build-and-push created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply -f tekton/minimal-image-build/02-ace-minimal-build-image-build-and-push-task.yaml
task.tekton.dev/ace-minimal-build-image-build-and-push created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply -f tekton/minimal-image-build/ace-minimal-image-pipeline.yaml
pipeline.tekton.dev/ace-minimal-image-pipeline created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply -f tekton/minimal-image-build/ace-minimal-build-image-pipeline.yaml
pipeline.tekton.dev/ace-minimal-build-image-pipeline created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ vi tekton/minimal-image-build/ace-minimal-build-image-pipeline
ace-minimal-build-image-pipeline-run.yaml  ace-minimal-build-image-pipeline.yaml
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ vi tekton/minimal-image-build/ace-minimal-build-image-pipeline
ace-minimal-build-image-pipeline-run.yaml  ace-minimal-build-image-pipeline.yaml
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ vi tekton/minimal-image-build/ace-minimal-build-image-pipeline-run.yaml
<Change the download URL>
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl create secret docker-registry ibm-entitlement-key --docker-username=cp --docker-password=ibmEntitlementKey --docker-server=cp.icr.io
secret/ibm-entitlement-key created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ tkn pr delete ace-minimal-build-image-pipeline-run-1 -f ; kubectl apply -f tekton/minimal-image-build/ace-minimal-build-image-pipeline-run.yaml
PipelineRuns deleted: "ace-minimal-build-image-pipeline-run-1"
pipelinerun.tekton.dev/ace-minimal-build-image-pipeline-run-1 created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ tkn pr logs ace-minimal-build-image-pipeline-run-1 -f
[runtime-image : clone] Cloning into 'ace-docker'...
[runtime-image : clone] total 120
[runtime-image : clone] -rw-r--r--    1 root     root          6711 Apr  8 17:49 Dockerfile.alpine
[runtime-image : clone] -rw-r--r--    1 root     root          6940 Apr  8 17:49 Dockerfile.alpine-java11
[runtime-image : clone] -rw-r--r--    1 root     root          4963 Apr  8 17:49 Dockerfile.ubuntu

<truncated build output ...>

[build-image : ace-minimal-build-push] INFO[0028] CMD ["/bin/bash"]
[build-image : ace-minimal-build-push] INFO[0028] Pushing image to 192.168.49.2:5000/default/ace-minimal-build:12.0.11.0-alpine
[build-image : ace-minimal-build-push] INFO[0028] Pushed 192.168.49.2:5000/default/ace-minimal-build@sha256:c3fcc0155163ed528a7d3c0801a32b93f79b30007865eb095881f353a2edf320

ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply -f tekton/10-ibmint-ace-build-task.yaml
task.tekton.dev/ace-build created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply -f tekton/20-deploy-to-cluster-task.yaml
task.tekton.dev/deploy-to-cluster created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply -f tekton/21-knative-deploy-task.yaml
task.tekton.dev/knative-deploy created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply -f tekton/ace-pipeline.yaml
pipeline.tekton.dev/ace-pipeline created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ tkn pr delete ace-pipeline-run-1 -f  ; kubectl apply -f tekton/ace-pipeline-run.yaml
Error: pipelineruns.tekton.dev "ace-pipeline-run-1" not found
pipelinerun.tekton.dev/ace-pipeline-run-1 created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ tkn pr logs ace-pipeline-run-1 -f
[build-from-source : clone] Cloning into 'ace-demo-pipeline'...
[build-from-source : clone] Setting container tag to 20240408175811-f07980e

[build-from-source : ibmint-build] mqsicreateworkdir: Copying sample server.config.yaml to work directory

<truncated build output ...>

[deploy-to-cluster : deploy-app] deployment.apps/tea-tekton created

[deploy-to-cluster : create-service] service/tea-tekton-service created

ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ minikube addons enable ingress
💡  ingress is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.
You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS
    ▪ Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v20231011-8b53cabe0
    ▪ Using image registry.k8s.io/ingress-nginx/controller:v1.9.4
    ▪ Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v20231011-8b53cabe0
🔎  Verifying ingress addon...
🌟  The 'ingress' addon is enabled
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply -f tekton/minikube/tea-tekton-minikube-ingress.yaml
ingress.networking.k8s.io/tea-ingress created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl port-forward --address 0.0.0.0 svc/tea-tekton-service 7800:7800 &
[1] 286857
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ Forwarding from 0.0.0.0:7800 -> 7800

ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ curl http://localhost:7800/tea/index/1
Handling connection for 7800
{"name":"Assam","strength":5}


ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.12.1/serving-crds.yaml
customresourcedefinition.apiextensions.k8s.io/certificates.networking.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/configurations.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/clusterdomainclaims.networking.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/domainmappings.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/ingresses.networking.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/metrics.autoscaling.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/podautoscalers.autoscaling.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/revisions.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/routes.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/serverlessservices.networking.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/services.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/images.caching.internal.knative.dev created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.11.6/eventing-crds.yaml
customresourcedefinition.apiextensions.k8s.io/apiserversources.sources.knative.dev created
customresourcedefinition.apiextensions.k8s.io/brokers.eventing.knative.dev created
customresourcedefinition.apiextensions.k8s.io/channels.messaging.knative.dev created
customresourcedefinition.apiextensions.k8s.io/containersources.sources.knative.dev created
customresourcedefinition.apiextensions.k8s.io/eventtypes.eventing.knative.dev created
customresourcedefinition.apiextensions.k8s.io/parallels.flows.knative.dev created
customresourcedefinition.apiextensions.k8s.io/pingsources.sources.knative.dev created
customresourcedefinition.apiextensions.k8s.io/sequences.flows.knative.dev created
customresourcedefinition.apiextensions.k8s.io/sinkbindings.sources.knative.dev created
customresourcedefinition.apiextensions.k8s.io/subscriptions.messaging.knative.dev created
customresourcedefinition.apiextensions.k8s.io/triggers.eventing.knative.dev created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.12.1/serving-core.yaml

namespace/knative-serving created
role.rbac.authorization.k8s.io/knative-serving-activator created
clusterrole.rbac.authorization.k8s.io/knative-serving-activator-cluster created
clusterrole.rbac.authorization.k8s.io/knative-serving-aggregated-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/knative-serving-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-admin created
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-edit created
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-view created
clusterrole.rbac.authorization.k8s.io/knative-serving-core created
clusterrole.rbac.authorization.k8s.io/knative-serving-podspecable-binding created
serviceaccount/controller created
clusterrole.rbac.authorization.k8s.io/knative-serving-admin created
clusterrolebinding.rbac.authorization.k8s.io/knative-serving-controller-admin created
clusterrolebinding.rbac.authorization.k8s.io/knative-serving-controller-addressable-resolver created
serviceaccount/activator created
rolebinding.rbac.authorization.k8s.io/knative-serving-activator created
clusterrolebinding.rbac.authorization.k8s.io/knative-serving-activator-cluster created
customresourcedefinition.apiextensions.k8s.io/images.caching.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/certificates.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/configurations.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/clusterdomainclaims.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/domainmappings.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/ingresses.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/metrics.autoscaling.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/podautoscalers.autoscaling.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/revisions.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/routes.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/serverlessservices.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/services.serving.knative.dev unchanged
secret/serving-certs-ctrl-ca created
secret/knative-serving-certs created
secret/routing-serving-certs created
image.caching.internal.knative.dev/queue-proxy created
configmap/config-autoscaler created
configmap/config-defaults created
configmap/config-deployment created
configmap/config-domain created
configmap/config-features created
configmap/config-gc created
configmap/config-leader-election created
configmap/config-logging created
configmap/config-network created
configmap/config-observability created
configmap/config-tracing created
horizontalpodautoscaler.autoscaling/activator created
poddisruptionbudget.policy/activator-pdb created
deployment.apps/activator created
service/activator-service created
deployment.apps/autoscaler created
service/autoscaler created
deployment.apps/controller created
service/controller created
horizontalpodautoscaler.autoscaling/webhook created
poddisruptionbudget.policy/webhook-pdb created
deployment.apps/webhook created
service/webhook created
validatingwebhookconfiguration.admissionregistration.k8s.io/config.webhook.serving.knative.dev created
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.serving.knative.dev created
validatingwebhookconfiguration.admissionregistration.k8s.io/validation.webhook.serving.knative.dev created
secret/webhook-certs created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v1.12.1/kourier.yaml
namespace/kourier-system created
configmap/kourier-bootstrap created
configmap/config-kourier created
serviceaccount/net-kourier created
clusterrole.rbac.authorization.k8s.io/net-kourier created
clusterrolebinding.rbac.authorization.k8s.io/net-kourier created
deployment.apps/net-kourier-controller created
service/net-kourier-controller created
deployment.apps/3scale-kourier-gateway created
service/kourier created
service/kourier-internal created
horizontalpodautoscaler.autoscaling/3scale-kourier-gateway created
poddisruptionbudget.policy/3scale-kourier-gateway-pdb created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl patch configmap/config-network -n knative-serving --type merge -p '{"data":{"ingress.class":"kourier.ingress.networking.knative.dev"}}'
configmap/config-network patched
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl apply -f https://projectcontour.io/quickstart/contour.yaml

namespace/projectcontour created
serviceaccount/contour created
serviceaccount/envoy created
configmap/contour created
customresourcedefinition.apiextensions.k8s.io/contourconfigurations.projectcontour.io created
customresourcedefinition.apiextensions.k8s.io/contourdeployments.projectcontour.io created
customresourcedefinition.apiextensions.k8s.io/extensionservices.projectcontour.io created
customresourcedefinition.apiextensions.k8s.io/httpproxies.projectcontour.io created
customresourcedefinition.apiextensions.k8s.io/tlscertificatedelegations.projectcontour.io created
serviceaccount/contour-certgen created
rolebinding.rbac.authorization.k8s.io/contour created
role.rbac.authorization.k8s.io/contour-certgen created
job.batch/contour-certgen-v1-28-2 created
clusterrolebinding.rbac.authorization.k8s.io/contour created
rolebinding.rbac.authorization.k8s.io/contour-rolebinding created
clusterrole.rbac.authorization.k8s.io/contour created
role.rbac.authorization.k8s.io/contour created
service/contour created
service/envoy created
deployment.apps/contour created
daemonset.apps/envoy created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ cat <<EOF | kubectl apply -n kourier-system -f -
> apiVersion: networking.k8s.io/v1
> kind: Ingress
> metadata:
>   name: kourier-ingress
>   namespace: kourier-system
> spec:
>   rules:
>   - http:
>      paths:
>        - path: /
>          pathType: Prefix
>          backend:
>            service:
>              name: kourier
>              port:
>                number: 80
> EOF
ingress.networking.k8s.io/kourier-ingress created
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ export ksvc_domain="\"data\":{\""$(minikube ip)".nip.io\": \"\"}"
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kubectl patch configmap/config-domain -n knative-serving --type merge  -p "{$ksvc_domain}"
configmap/config-domain patched
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ tkn pr delete ace-pipeline-run-1 -f  ; kubectl apply -f tekton/ace-pipeline-run.yaml ; tkn pr logs ace-pipeline-run-1 -f
PipelineRuns deleted: "ace-pipeline-run-1"
pipelinerun.tekton.dev/ace-pipeline-run-1 created
[build-from-source : clone] Cloning into 'ace-demo-pipeline'...

<truncated build output ...>

[build-from-source : docker-build-and-push] Mon Apr  8 18:51:46 UTC 2024

[deploy-knative-to-cluster : clone] + cd /work
[deploy-knative-to-cluster : clone] + git clone -b aceaas-and-minikube https://github.com/trevor-dolby-at-ibm-com/ace-demo-pipeline
[deploy-knative-to-cluster : clone] Cloning into 'ace-demo-pipeline'...
[deploy-knative-to-cluster : clone] + echo 192.168.49.2:5000/default
[deploy-knative-to-cluster : clone] + sed 's/\//\\\//g'
[deploy-knative-to-cluster : clone] + export 'REG_WITH_ESCAPED_SLASH=192.168.49.2:5000\/default'
[deploy-knative-to-cluster : clone] + echo '192.168.49.2:5000\/default'
[deploy-knative-to-cluster : clone] + sed -i 's/DOCKER_REGISTRY/192.168.49.2:5000\/default/g' /work/ace-demo-pipeline/extensions/serverless/tea-tekton-knative-service.yaml
[deploy-knative-to-cluster : clone] 192.168.49.2:5000\/default
[deploy-knative-to-cluster : clone] + export 'TAG=20240408185001-f07980e'
[deploy-knative-to-cluster : clone] + echo Using 20240408185001-f07980e as image tag
[deploy-knative-to-cluster : clone] Using 20240408185001-f07980e as image tag
[deploy-knative-to-cluster : clone] + sed -i s/IMAGE_TAG/20240408185001-f07980e/g /work/ace-demo-pipeline/extensions/serverless/knative-service-account.yaml /work/ace-demo-pipeline/extensions/serverless/tea-tekton-knative-service.yaml
[deploy-knative-to-cluster : clone] + cat /work/ace-demo-pipeline/extensions/serverless/tea-tekton-knative-service.yaml
[deploy-knative-to-cluster : clone] apiVersion: serving.knative.dev/v1
[deploy-knative-to-cluster : clone] kind: Service
[deploy-knative-to-cluster : clone] metadata:
[deploy-knative-to-cluster : clone]   name: tea-tekton-knative
[deploy-knative-to-cluster : clone] spec:
[deploy-knative-to-cluster : clone]   template:
[deploy-knative-to-cluster : clone]     spec:
[deploy-knative-to-cluster : clone]       volumes:
[deploy-knative-to-cluster : clone]       - name: secret-volume-2
[deploy-knative-to-cluster : clone]         secret:
[deploy-knative-to-cluster : clone]           secretName: jdbc-secret
[deploy-knative-to-cluster : clone]       imagePullSecrets:
[deploy-knative-to-cluster : clone]       - name: regcred
[deploy-knative-to-cluster : clone]       containers:
[deploy-knative-to-cluster : clone]       - name: tea-tekton-knative
[deploy-knative-to-cluster : clone]         image: 192.168.49.2:5000/default/tea-tekton:20240408185001-f07980e
[deploy-knative-to-cluster : clone]         ports:
[deploy-knative-to-cluster : clone]         - containerPort: 7800
[deploy-knative-to-cluster : clone]         volumeMounts:
[deploy-knative-to-cluster : clone]         - name: secret-volume-2
[deploy-knative-to-cluster : clone]           mountPath: /var/run/secrets/jdbc

[deploy-knative-to-cluster : create-knative-service] Warning: Kubernetes default value is insecure, Knative may default this to secure in a future release: spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation, spec.template.spec.containers[0].securityContext.capabilities, spec.template.spec.containers[0].securityContext.runAsNonRoot, spec.template.spec.containers[0].securityContext.seccompProfile
[deploy-knative-to-cluster : create-knative-service] service.serving.knative.dev/tea-tekton-knative configured

ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kn services list
NAME                 URL                                                     LATEST                     AGE     CONDITIONS   READY     REASON
tea-tekton-knative   http://tea-tekton-knative.default.192.168.49.2.nip.io   tea-tekton-knative-00002   8m51s   1 OK / 3     Unknown
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ kn services list
NAME                 URL                                                     LATEST                     AGE    CONDITIONS   READY   REASON
tea-tekton-knative   http://tea-tekton-knative.default.192.168.49.2.nip.io   tea-tekton-knative-00003   9m5s   3 OK / 3     True
ubuntu@minikube-20231123:~/github.com/ace-demo-pipeline$ curl http://tea-tekton-knative.default.192.168.49.2.nip.io/tea/index/1
{"name":"Assam","strength":5}
```
