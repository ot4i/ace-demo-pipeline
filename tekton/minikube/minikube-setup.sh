
minikube start --insecure-registry "192.168.0.0/16"
minikube addons enable dashboard
minikube addons enable registry
minikube addons enable metrics-server
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml
kubectl create secret docker-registry regcred --docker-server=us.icr.io --docker-username=notused --docker-password=notused
kubectl create secret generic jdbc-secret --from-literal=USERID='BLAH' --from-literal=PASSWORD='BLAH' --from-literal=databaseName='BLUDB' --from-literal=serverName='19af6446-6171-4641-8aba-9dcff8e1b6ff.c1ogj3sd0tgtu0lqde00.databases.appdomain.cloud' --from-literal=portNumber='30699'

kubectl apply -f tekton/service-account.yaml

kubectl apply -f tekton/minimal-image-build/01-ace-minimal-image-build-and-push-task.yaml
kubectl apply -f tekton/minimal-image-build/02-ace-minimal-build-image-build-and-push-task.yaml
kubectl apply -f tekton/minimal-image-build/ace-minimal-image-pipeline.yaml
kubectl apply -f tekton/minimal-image-build/ace-minimal-build-image-pipeline.yaml
tkn pr delete ace-minimal-image-pipeline-run-1 -f  ; kubectl apply -f tekton/minimal-image-build/ace-minimal-image-pipeline-run-minikube.yaml
tkn pr logs ace-minimal-image-pipeline-run-1 -f
tkn pr delete ace-minimal-build-image-pipeline-run-1 -f  ; kubectl apply -f tekton/minimal-image-build/ace-minimal-build-image-pipeline-run-minikube.yaml
tkn pr logs ace-minimal-build-image-pipeline-run-1 -f

kubectl apply -f tekton/10-maven-ace-build-task.yaml
kubectl apply -f tekton/20-deploy-to-cluster-task.yaml
kubectl apply -f tekton/ace-pipeline.yaml
tkn pr delete ace-pipeline-run-1 -f  ; kubectl apply -f tekton/ace-pipeline-run-minikube.yaml
tkn pr logs ace-pipeline-run-1 -f

minikube addons enable ingress














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


cat serverless/tea-tekton-knative-service.yaml | sed 's/DOCKER_REGISTRY/192.168.49.2:5000\/default/g' | kubectl apply -f -

curl -LO https://github.com/knative/client/releases/download/knative-v1.11.2/kn-linux-amd64


oc create secret docker-registry ibm-entitlement-key --docker-username=cp --docker-password=myEntitlementKey --docker-server=cp.icr.io --namespace=cp4i
