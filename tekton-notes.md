# Using Tekton to build this project

Rough notes from initial attempt

Using same IBM Cloud kubernetes cluster as before.

```
kubectl create secret docker-registry regcred --docker-server=uk.icr.io --docker-username=iamapikey --docker-password=<your-key>
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/service-account.yaml

kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

kubectl apply -f ./01-ace-minimal-image-build-and-push-task.yaml
kubectl apply -f ./ace-minimal-image-pipeline.yaml

tkn pipelinerun delete -f ace-minimal-image-pipeline-run-1 ; kubectl apply -f ./ace-minimal-image-pipeline-run.yaml && tkn pipelinerun logs ace-minimal-image-pipeline-run-1 -f

kubectl apply -f ./02-ace-minimal-build-image-build-and-push-task.yaml
kubectl apply -f ./ace-minimal-build-image-pipeline.yaml

tkn pipelinerun delete -f ace-minimal-build-image-pipeline-run-1 ; kubectl apply -f ./ace-minimal-build-image-pipeline-run.yaml && tkn pipelinerun logs ace-minimal-build-image-pipeline-run-1 -f


kubectl apply -f ./10-maven-ace-build-task.yaml
kubectl apply -f ./20-deploy-to-cluster-task.yaml
kubectl apply -f ./ace-pipeline.yaml

tkn pipelinerun delete -f ace-pipeline-run-1 ; kubectl apply -f ./ace-pipeline-run.yaml && tkn pipelinerun logs ace-pipeline-run-1 -f


kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/10-maven-ace-build-task.yaml
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/20-deploy-to-cluster-task.yaml
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/ace-pipeline.yaml

tkn pipelinerun delete -f ace-pipeline-run-1 ; kubectl apply -f https://raw.githubusercontent.com//ace-demo-pipeline/master/tekton/ace-pipeline-run.yaml && tkn pipelinerun logs ace-pipeline-run-1 -f




kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml

kubectl --namespace tekton-pipelines port-forward --address 0.0.0.0 svc/tekton-dashboard 9097:9097

```

AKS:
```
kubectl create secret docker-registry regcred --docker-server=aceDemoRegistry.azurecr.io --docker-username=aceDemoRegistry --docker-password=<your-key>
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/service-account.yaml

kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/01-ace-minimal-image-build-and-push-task.yaml
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/ace-minimal-image-pipeline.yaml


kubectl apply -f ~tdolby/github.ibm.com/ace-demo-pipeline/tekton/ace-minimal-image-pipeline-run-aks.yaml


tkn pipelinerun delete -f ace-minimal-image-pipeline-run-1 ; kubectl apply -f  https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/ace-minimal-image-pipeline-run-aks.yaml && tkn pipelinerun logs ace-minimal-image-pipeline-run-1 -f



kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/02-ace-minimal-build-image-build-and-push-task.yaml
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/ace-minimal-build-image-pipeline.yaml

tkn pipelinerun delete -f ace-minimal-build-image-pipeline-run-1 ; kubectl apply -f ~tdolby/github.ibm.com/ace-demo-pipeline/tekton/ace-minimal-build-image-pipeline-run-aks.yaml && tkn pipelinerun logs ace-minimal-build-image-pipeline-run-1 -f




kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/10-maven-ace-build-task.yaml
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/20-deploy-to-cluster-task.yaml
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/ace-pipeline.yaml

tkn pipelinerun delete -f ace-pipeline-run-1 ; kubectl apply -f ~tdolby/github.ibm.com/ace-demo-pipeline/tekton/ace-pipeline-run-aks.yaml && tkn pipelinerun logs ace-pipeline-run-1 -f



```

kubectl create secret docker-registry regcred --docker-server=us.icr.io --docker-username=iamapikey --docker-password=<your-key>

kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/01-ace-minimal-image-build-and-push-task.yaml
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/ace-minimal-image-pipeline.yaml
kubectl apply -f ~tdolby/github.ibm.com/ace-demo-pipeline/tekton/ace-minimal-image-pipeline-run.yaml

tkn pipelinerun delete -f ace-minimal-image-pipeline-run-1 ; kubectl apply -f  https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/ace-minimal-image-pipeline-run.yaml && tkn pipelinerun logs ace-minimal-image-pipeline-run-1 -f

kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/02-ace-minimal-build-image-build-and-push-task.yaml
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/ace-minimal-build-image-pipeline.yaml
tkn pipelinerun delete -f ace-minimal-build-image-pipeline-run-1 ; kubectl apply -f ~tdolby/github.com/ace-demo-pipeline/tekton/ace-minimal-build-image-pipeline-run.yaml && tkn pipelinerun logs ace-minimal-build-image-pipeline-run-1 -f

kubectl delete pod force-pull
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/force-pull-of-images.yaml

kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/10-maven-ace-build-task.yaml
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/20-deploy-to-cluster-task.yaml
kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/ace-pipeline.yaml
tkn pipelinerun delete -f ace-pipeline-run-1 ; kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/ace-pipeline-run.yaml && tkn pipelinerun logs ace-pipeline-run-1 -f


kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/30-verify-service-running-task-iks.yaml

tkn taskrun delete -f verify-service-running-taskrun-1 ; kubectl apply -f https://raw.githubusercontent.com/ot4i/ace-demo-pipeline/demo-pipeline-21-06/tekton/verify-service-running-taskrun.yaml ; tkn taskrun logs verify-service-running-taskrun-1 -f
