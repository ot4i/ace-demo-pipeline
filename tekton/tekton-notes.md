# Using Tekton to build this project

Rough notes from initial attempt

Using same IBM Cloud kubernetes cluster as before.

```
kubectl create secret docker-registry regcred --docker-server=uk.icr.io --docker-username=iamapikey --docker-password=<your-key>
kubectl apply -f https://raw.githubusercontent.com/tdolby-at-uk-ibm-com/ace-pipeline-demo-21-02/main/tekton/service-account.yaml


kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.21.0/release.yaml
kubectl apply -f https://raw.githubusercontent.com/tdolby-at-uk-ibm-com/ace-pipeline-demo-21-02/main/tekton/10-maven-ace-build-task.yaml
kubectl apply -f https://raw.githubusercontent.com/tdolby-at-uk-ibm-com/ace-pipeline-demo-21-02/main/tekton/20-deploy-to-cluster-task.yaml
kubectl apply -f https://raw.githubusercontent.com/tdolby-at-uk-ibm-com/ace-pipeline-demo-21-02/main/tekton/ace-pipeline.yaml

tkn pipelinerun delete -f ace-pipeline-run-1
kubectl apply -f https://raw.githubusercontent.com/tdolby-at-uk-ibm-com/ace-pipeline-demo-21-02/main/tekton/ace-pipeline-run.yaml
tkn pipelinerun logs ace-pipeline-run-1 -f


```
