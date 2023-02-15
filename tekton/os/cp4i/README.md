# CP4i pipeline

This pipeline is similar to the main project pipeline, but is designed to work with the Cloud Pak for Integration (CP4i) 
and uses the App Connect Enterprise certified containers for runtime. It also runs component tests in a CP4i container to
allow JDBC connections to be tested using the same CP4i configurations used by the deployed application itself.

![Pipeline overview](images/cp4i-pipeline.png)

## Container builds

The pipeline creates the main application image first, and then builds the component test image on top of the first image.
Kaniko is used to build both images in the pipeline, with Maven building the applications and libraries.

![Container images](images/cp4i-container-images.png)

## Component testing

The component testing itself relies on the operator support code (runaceserver) to create the correct policies and
credentials from the configurations provided. This allows the component tests to run with the same setup as the application
itself, ensuring the tests are providing useful results.

![work directory](images/cp4i-work-dir.png)

The test run strategy is as follows:

- Create a CR with MQSI_PREVENT_CONTAINER_SHUTDOWN set plus the database credentials configurations (and any other needed configurations) using the second custom image (the one with the tests), and let it start up.
- Stop the running server with kill -INT 1 (via kubectl exec) to cause the runaceserver code to shut the server down and then wait (due to MQSI_PREVENT_CONTAINER_SHUTDOWN  being set).
- Once the server is stopped, run a new server (using kubectl exec or whatever) that specifies the correct test project and any test options (like IntegrationServer -w /home/aceuser/ace-server --test-project SomeTestProject --start-msgflows false)
- Collect the output and return code from kubectl exec as usual, allowing the pipeline to stop on failed tests.
- Delete the CR, and then send another kill -INT 1 to make the runaceserver code exit.

See [13-component-test-in-cp4i-task.yaml](13-component-test-in-cp4i-task.yaml) for details on running the tests.

Note that this splits responsibilities between the ACE operator (create the work directory and run the initial server) and the
ACE product itself (run the tests and report the results); the operator support code in the container does not know anything
about running tests. 
- Anything that would also affect production (such as issues with CP4i configuration formats and other related matters) would fall under CP4i support.
- Issues with ACE application code, JUnit options, etc, would fall under ACE product support.
- As the tests are using the operator, the [ot4i/ace-docker](https://github.com/ot4i/ace-docker) repo is not involved, so issues should be 
  raised with product support (CP4i or ACE itself) rather than in that repo; ace-docker is now intended only for non-operator use cases.

## Pipeline setup and run

Many of the steps are the same as the main repo, but use the `cp4i` namespace. Security constraints are more of an issue
in OpenShift, and Kaniko seems to require quite a lot of extra permissions when not running in the default namespace.

The pipeline assumes the CP4i ACE integration server image has been copied to the local image registry to make the
container builds go faster; the image must match the locations in the YAML files. See 
https://www.ibm.com/docs/en/app-connect/containers_cd?topic=obtaining-app-connect-enterprise-server-image-from-cloud-container-registry
for details on the available images.

For example, the following sequence would tage the 12.0.7.0-r3 image and upload to the registry:
```
docker pull cp.icr.io/cp/appc/ace-server-prod@sha256:e1940cfedde96de2cdd345a7ca8184a69f57963874faffcd6da670243aecad47
docker tag cp.icr.io/cp/appc/ace-server-prod@sha256:e1940cfedde96de2cdd345a7ca8184a69f57963874faffcd6da670243aecad47 image-registry.openshift-image-registry.svc.cluster.local:5000/default/ace-server-prod:12.0.7.0-r3
docker push image-registry.openshift-image-registry.svc.cluster.local:5000/default/ace-server-prod:12.0.7.0-r3
```

Configurations need to be created for the JDBC credentials (teajdbc-policy and teajdbc) and default policy project name
in a server.conf.yaml configuration (default-policy). See [configurations/README.md](configurations/README.md) for details.

The initial commands are 
```
kubectl create secret generic jdbc-secret --from-literal=USERID='USERNAME' --from-literal=PASSWORD='PASSWORD' --from-literal=databaseName='BLUDB' --from-literal=serverName='19af6446-6171-4641-8aba-9dcff8e1b6ff.c1ogj3sd0tgtu0lqde00.databases.appdomain.cloud' --from-literal=portNumber='30699'
kubectl create secret -n cp4i docker-registry regcred --docker-server=image-registry.openshift-image-registry.svc.cluster.local:5000 --docker-username=kubeadmin --docker-password=$(oc whoami -t)
kubectl apply -f tekton/os/cp4i/cp4i-scc.yaml
kubectl apply -f tekton/os/cp4i/service-account-cp4i.yaml
oc adm policy add-scc-to-user cp4i-scc -n cp4i -z cp4i-tekton-service-account
kubectl apply -f tekton/os/cp4i/12-maven-cp4i-build-task.yaml
kubectl apply -f tekton/os/cp4i/13-component-test-in-cp4i-task.yaml
kubectl apply -f tekton/os/cp4i/22-deploy-to-cp4i-task.yaml
kubectl apply -f tekton/os/cp4i/cp4i-pipeline.yaml
```
and to run the pipeline
```
kubectl apply -f tekton/os/cp4i/cp4i-pipeline-run.yaml
tkn pipelinerun -n cp4i logs cp4i-pipeline-run-1 -f
```

## Results

If the pipeline is successful, there should be an integration server CR called `tea-tekton-cp4i` in the cp4i namespace.
A route should have been created, and the application can be checked by querying the URL

http://tea-tekton-cp4i-http-cp4i.apps.openshift.domain.name/tea/index/1

(with the appropriate domain name) to call the tea application.

