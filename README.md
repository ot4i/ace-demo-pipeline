# ACE demo pipeline

Demo pipeline for ACE to show how ACE solutions can be built in CI/CD pipelines using standard 
tools. The main focus is on how to use existing ACE capabilities in a pipeline, with the application
being constructed to show pipeline-friendliness rather than being a "best practice" application.

The overall goal is to deploy a running REST application to an ACE integration server:

![Pipeline high-level](/demo-infrastructure/images/pipeline-high-level.png)

The application used to demonstrate the pipeline consists of a REST API that accepts JSON and interacts 
with a database, with a supporting shared library containing a lot of the code. It is designed around 
indexing different types of tea, storing the name and strength of the tea and assigning a unique integer 
id to each type so that it can be retrieved later. Audit data is logged as XML for each operation performed.

Testing is split into “Unit Test” and "Component Test” categories, where "unit tests" are self-contained
and do not connect to external services (so they can run reliably anywhere) while the term “component test”
was used in the ACE product development pipeline to mean “unit tests that use external services”. See 
[ACE unit and component tests](https://community.ibm.com/community/user/integration/blogs/trevor-dolby/2023/03/20/app-connect-enterprise-ace-unit-and-component-test)
for a discussion of the difference between test styles in integration.

## Technology and target options

This repo can be built in several different ways, and can deploy to different targets:

![Pipeline overview](/demo-infrastructure/images/pipelines-overview.jpg)

Pipeline technology options currently include:

- [GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions)
  for CI build and test before PRs are merged. This requires a GitHub instance that supports actions 
  (not all Enterprise variants do), and credit enough to run the actions. There is currently no 
  component testing nor a deploy target (though these could be added) for these builds.
- [Tekton](https://tekton.dev/docs/concepts/overview/) can be used to build, test, and deploy the Tea
  REST application to runtime infrastructure. Tekton is the basis for many Kubernetes application build
  pipelines and also underpins RedHat OpenShift Pipelines.
- [Jenkins](https://www.jenkins.io/) can be used to build, test, and deploy the Tea REST application 
  to runtime infrastructure. Jenkins is widely used in many organizations for build and deployment.

ACE deploy targets currently include:

- Kubernetes containers, with both standalone ACE containers and ACE certified containers (via the 
  ACE operator) as possible runtimes. Minikube and OpenShift can be used with the former, while
  the latter expects to deploy to the Cloud Pak for Integration (CP4i).
- [ACE-as-a-Service](https://www.ibm.com/docs/en/app-connect/12.0?topic=app-connect-enterprise-as-service)
  running on AWS. This option requires an instance (which can be a trial instance) of ACEaaS to be 
  available but does not require any software to be installed and the flows run entirely in the cloud.
- An ACE integration node, using an existing ACE integration node.

As can be seen from the diagram above, not all deployment options have been configured for all of
the pipeline options, but more could be added as needed. 

As well as multiple options for pipelines and deploy targets, multiple build tools can be used to 
build and test the application in the pipeline and locally:

- Standard ACE commands introduced at v12 (such as ibmint).
- Maven can also be used, and was the default in the ACE v11 version of this repo.
- Gradle can be used to run builds and unit tests, but has not been enabled for component tests.
- The toolkit can build and run the application and tests.



## Constituent parts

- This repo, containing the application source and tests plus the DB2 client JAR.
- Maven for building applications and running JUnit tests
- Tekton for running builds in a cloud
- Docker container build files in this repo for building the application image (see tekton/Dockerfile)
- IBM Cloud container registry (free tier) for hosting the application image
- IBM Cloud Kubernetes cluster (free tier) for running the application container
- DB2 on Cloud (free tier) for use by the application container; credentials stored in Kubernetes secrets

This repo can also be built using a GitHub action for CI enablement. It is also possible to run the
pipeline using OpenShift with RedHat OpenShift Pipelines instead of using the IBM Cloud Kubernetes 
service, and the instructions contain OpenShift-specific sections for the needed changes. 

There is also a variant of the pipeline that uses the IBM Cloud Pak for Integration and creates
custom resources to deploy the application (amongst other changes). See the 
[CP4i README](tekton/os/cp4i/README.md) for details and instructions.
 
Jenkins can also be used to run the pipeline and deploy the application to an integration node.
See the [Jenkins README](demo-infrastructure/README-jenkins.md) for details and instructions.
 
Note that the Tekton pipeline can also create temporary databases for use during pipeline runs; see 
[temp-db2](tekton/temp-db2/README.md) for more details.

For online testing and development, see [README-codespaces](README-codespaces.md) for details on
using a github-hosted container.

## The application

The application used to demonstrate the pipeline consists of a REST API that accepts JSON and interacts 
with a database, with a supporting shared library containing a lot of the code. It is designed around 
indexing different types of tea, storing the name and strength of the tea and assigning a unique integer 
id to each type so that it can be retrieved later. Audit data is logged as XML for each operation performed.

This repo can be imported into the ACE v12 toolkit using the egit plugin (included in the ACE v12 toolkit)
and inspected; as most pipelines would be expected to work with source repositories, there is no project 
interchange file to import for the projects.

As this application exists to help demonstrate pipelines and how they work with ACE, there are some shortcuts 
in the code that would not normally be present in a production-ready application: the database table is 
created on-demand to make setup easier, the logging goes to the console instead of an audit service, etc. 
Maven is used for many builds but the configuration is deliberately constructed to make the steps as explicit
as possible, bash is used for other builds scripts, etc.

## The tests

Unit tests reside in TeaRESTApplication_UnitTest along with their own test data.

Component testing is run from TeaRESTApplication_ComponentTest and relies on JDBC connections.

## How to get started with IBM Cloud

To replicate the pipeline locally, do the following:

1) Fork this repo and then clone it locally; although cloning it locally straight from the ot4i repo would allow building locally, for the pipeline itself to work some of the files need to be updated. The source also needs to be accessible to the IBM Cloud Kubernetes workers, and a public github repo forked from this one is the easiest way to do this. Cloning can be achieved with the git command line, or via the ACE v12 toolkit; the ACE v12 product can be downloaded from [the IBM website](https://www.ibm.com/marketing/iwm/iwm/web/pickUrxNew.do?source=swg-wmbfd).
2) Acquire an IBM Cloud account and create a Kubernetes cluster called "aceCluster", a Docker registry, and a DB2 on Cloud instance. More info in [cloud resources description](demo-infrastructure/cloud-resources.md).
3) Build the pre-req docker images and create the required credentials; see instructions in the [demo-infrastructure](demo-infrastructure) and [tekton/minimal-image-build](tekton/minimal-image-build) directories.
4) Component testing relies on the same DB2 on Cloud instance as the eventual application image; this is not a best practice, but does keep the demo simpler to get going, and so getting the DB2 instance credentials set up in Kubernetes and/or locally is necessary for the component tests.
5) Try running the pipeline using the instructions in the [tekton](tekton) directory.
6) Optionally, enable GitHub actions; this requires a GitHub instance that supports actions (not all Enterprise variants do), and credit enough to run the actions.
