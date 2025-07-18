# ACE demo pipeline

Demo pipeline for ACE to show how ACE solutions can be built in CI/CD pipelines using standard 
tools. The main focus is on how to use existing ACE capabilities in a pipeline, with the application
being constructed to show pipeline-friendliness rather than being a "best practice" application.
As part of this, the pipeline scripts are stored in this repo along with the application source
to make the demo simpler, while in practice they would often be stored separately.

The overall goal is to deploy a REST HTTP application to an ACE integration server:

![Pipeline high-level](/demo-infrastructure/images/pipeline-high-level.png)

The application used to demonstrate the pipeline consists of a REST API that accepts JSON and interacts 
with a database via JDBC, with a supporting shared library containing a lot of the code (hereafter 
referred to as the "Tea REST application"). It is designed around indexing different types of tea, storing
the name and strength of the tea along with assigning a unique integer id to each type so that it can be 
retrieved later. Audit data is logged as XML for each operation performed.

As this application exists to help demonstrate pipelines and how they work with ACE, there are some shortcuts 
in the code that would not normally be present in a production-ready application: the database table is 
created on-demand to make setup easier, the logging goes to the console instead of an audit service, etc. 

## Recent changes

- Upgraded to [ACE 13.0.4](https://community.ibm.com/community/user/blogs/ben-thompson1/2025/06/18/ace-13-0-4-0)
- Uses [Crane](https://github.com/google/go-containerregistry/tree/main/cmd/crane) for faster container image builds.
- Added callable flow interface to enable [hybrid cloud scenarios](/extensions/iwhi/README.md) with IBM webMethods Hybrid Integration.

## Technology and target options

This repo can be built in several different ways, and can deploy to different targets (see
[Getting started](#getting-started) for suggestions on how to choose a target) from the same
source as shown in this diagram:

![Pipeline overview](/demo-infrastructure/images/pipelines-overview.jpg)

Testing is split into "Unit Test" and "Component Test" categories, where "unit tests" are self-contained
and do not connect to external services such as databases (so they can run reliably anywhere) while the
term "component test" was used in the ACE product development pipeline to mean "unit tests that use external
services (such as databases)". See 
[ACE unit and component tests](https://community.ibm.com/community/user/integration/blogs/trevor-dolby/2023/03/20/app-connect-enterprise-ace-unit-and-component-test)
for a discussion of the difference between test styles in integration.

Pipeline technology options currently include:

- [GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions)
  for CI build and test before pull requests (PRs) are merged. This requires a GitHub instance that supports
  actions (not all Enterprise variants do), and credit enough to run the actions. There is currently no 
  component testing nor a deploy target (though these could be added) for these builds.
- [Tekton](https://tekton.dev/docs/concepts/overview/) can be used to build, test, and deploy the Tea
  REST application to ACE runtime infrastructure such as Kubernetes containers. Tekton is the basis for 
  many Kubernetes application build pipelines and also underpins RedHat OpenShift Pipelines.
- [Jenkins](https://www.jenkins.io/) can be used to build, test, and deploy the Tea REST application 
  to ACE runtime infrastructure such as integration nodes. Jenkins is widely used in many organizations
  for build and deployment.

ACE deploy targets currently include:

- Kubernetes containers, with both standalone ACE containers and ACE certified containers (via the 
  ACE operator code) as possible runtimes. [Minikube](https://minikube.sigs.k8s.io/docs/) (easily installed
  locally) and OpenShift can be used with the former, while the latter expects to deploy to the Cloud
  Pak for Integration (CP4i). See [tekton/README.md#container-deploy-target](tekton/README.md#container-deploy-target)
  for a description of the container deploy pipelines.
- [ACE-as-a-Service](https://www.ibm.com/docs/en/app-connect/13.0?topic=app-connect-enterprise-as-service)
  (ACEaaS) running on Amazon Web Services (AWS). This option requires an instance (which can be a trial instance)
  of ACEaaS to be available but does not require ACE servers to managed directly (in virtual machines or containers)
  as the flows run entirely in the cloud. See [demo-infrastructure/README-aceaas-pipelines.md](demo-infrastructure/README-aceaas-pipelines.md)
  for an overview of the pipelines deploying to ACEaaS.
- An ACE integration node, using an existing ACE integration node.

As can be seen from the diagram above, not all deployment targets have been configured for all of
the pipeline technology options, but more could be added as needed. 

As well as multiple options for pipelines and deploy targets, multiple build tools can be used to 
build the ACE flows, Java code, Maps, etc and test the application in the pipeline and locally:

- Standard ACE commands introduced at v12 (such as ibmint) can be used to build, deploy, and test
  the application.
- Maven can also be used, and was the default in the ACE v11 version of this repo.
- Gradle can be used to run builds and unit tests, but has not been enabled for component tests.
- The toolkit can build and run the application and tests, and also to check source into the GitHub repo.

## Getting started

Regardless of the pipeline technology and deployment target, some initial steps are similar:

- Forking this repository is recommended as this allows experimentation with all aspects of
  the application and pipeline. PRs welcome, too!
- A database will be needed for the application to run correctly. GitHub Action CI builds can
  succeed without a database because they only run build and UT steps, but all other use cases
  require a database, and DB2 on Cloud (requires an IBM Cloud account) is one option that 
  requires no local setup nor any payment. For DB2oC, create a "free tier" DB2 instance via
  "Create resource" on the IBM Cloud dashboard and download the connection credentials for
  use in the pipeline. See [demo-infrastructure/cloud-resources.md](demo-infrastructure/cloud-resources.md)
  for more details.
  - Note that component testing relies on the same DB2 on Cloud instance as the eventual application 
    image; this is not a best practice, but does keep the demo simpler to get going, and so getting
    the DB2 instance credentials set up in Kubernetes and/or locally is necessary for the component tests.
- Installing the ACE toolkit locally is recommended, and the ACE v12 toolkit can clone the
  (forked) repo locally with the pre-installed eGit plugin. Although development and testing
  can be done online using a GitHub-hosted container (see [README-codespaces](README-codespaces.md) 
  for details), having the toolkit available locally is helpful for replicating the most common
  ACE development experience. See the developer edition [download page](https://www.ibm.com/docs/en/app-connect/13.0?topic=enterprise-download-ace-developer-edition-get-started)
  for a free version (limited to one transaction per second per flow) if your organization does
  not have existing ACE licenses.
  - Running the flows locally requires creating a JDBC policy called TEAJDBC in the default policy
    project for a server, creating the associated user/pw credentials, and then deploying the Tea flows
    and libraries. The server can be node-associated, but does not have to be.

Beyond those common steps, the choice of pipeline and target determine the next steps. The simplest 
way to choose the pipeline is to choose the target (Kubernetes, ACEaaS, or integration nodes), and
then pick one of the pipeline technologies that will deploy to that target. For advanced users who
are already familiar with pipelines it may better to start with a familiar pipeline technology and
then choose an available target.

- For Tekton deploying to Kubernetes, see [tekton/README.md](tekton/README.md) for instructions
  for the various container options and pipelines. 
  - See also [CP4i README](tekton/os/cp4i/README.md) for CP4i-specific variations, including 
    component testing in a CP4i container (as opposed to a build pipeline container) to ensure 
    credentials configurations are working as expected.
  - Note that the Tekton pipeline can also create temporary databases for use during pipeline runs; see 
    [temp-db2](tekton/temp-db2/README.md) for more details.
- Tekton-to-ACEaaS follows a similar pattern (see [tekton/README.md#ace-as-a-service-target](tekton/README.md#ace-as-a-service-target)),
  but does not need a runtime container as the runtime is in the cloud. Credentials are needed for the
  cloud service.
- For Jenkins, see the [Jenkins README](demo-infrastructure/README-jenkins.md) for details and 
  instructions on initial setup. 
  - Integration node targets require host/port/server information.
  - Additional steps are required for ACE-as-a-Service credentials.

