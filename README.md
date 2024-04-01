# ACE demo pipeline

Demo pipeline for ACE to show how ACE solutions can be built in CI/CD pipelines using standard 
tools. The main focus is on how to use existing ACE capabilities in a pipeline, with the application
being constructed to show pipeline-friendliness rather than being a "best practice" application.

The overall goal is to deploy a REST application to an ACE integration server:

![Pipeline high-level](/demo-infrastructure/images/pipeline-high-level.png)

The application used to demonstrate the pipeline consists of a REST API that accepts JSON and interacts 
with a database, with a supporting shared library containing a lot of the code. It is designed around 
indexing different types of tea, storing the name and strength of the tea and assigning a unique integer 
id to each type so that it can be retrieved later. Audit data is logged as XML for each operation performed.

As this application exists to help demonstrate pipelines and how they work with ACE, there are some shortcuts 
in the code that would not normally be present in a production-ready application: the database table is 
created on-demand to make setup easier, the logging goes to the console instead of an audit service, etc. 

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
  ACE operator) as possible runtimes. [Minikube](https://minikube.sigs.k8s.io/docs/) (easily installed
  locally) and OpenShift can be used with the former, while the latter expects to deploy to the Cloud
  Pak for Integration (CP4i).
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

## Getting started

Regardless of the pipeline technology and deployment target, some initial steps are similar:

- Forking this repository is recommended as this allows experimentation with all aspects of
  the application and pipeline.
- A database will be needed for the application to run correctly. GitHub Action CI builds can
  succeed without a database because they only run build and UT steps, but all other use cases
  require a database, and DB2 on Cloud (requires an IBM Cloud account) is one option that 
  requires no local setup nor any payment. For DB2oC, create a "free tier" DB2 instance via
  "Create resource" on the IBM Cloud dashboard and download the connection credentials for
  use in the pipeline.
- Installing the ACE toolkit locally is recommended, and the ACE v12 toolkit can clone the
  (forked) repo locally with the pre-installed eGit plugin. Although development and testing
  can be done online using a github-hosted container (see [README-codespaces](README-codespaces.md) 
  for details), having the toolkit available locally is helpful for replicating the most common
  ACE development experience.

Beyond those common steps, the choice of pipeline and target determine the next steps. The simplest 
way to choose the pipeline is to choose the target (Kubernetes, ACEaaS, or integration nodes), and
then pick one of the pipeline technologies that will deploy to that target.

- For Tekton deploying to Kubernetes, see [tekton/README.md](tekton/README.md) for instructions
  for the various container options and pipelines. 
  - See also [CP4i README](tekton/os/cp4i/README.md) for CP4i-specific variations, including 
    component testing in a CP4i container (as opposed to a build pipeline container) to ensure 
    credentials configurations are working as expected.
  - ACEaaS follows a similar pattern, but does not need a runtime container as the runtime is
    in the cloud.
  - Note that the Tekton pipeline can also create temporary databases for use during pipeline runs; see 
    [temp-db2](tekton/temp-db2/README.md) for more details.
- For Jenkins, see the [Jenkins README](demo-infrastructure/README-jenkins.md) for details and 
  instructions on initial setup. 
  - Integration node targets require host/port/server information.
  - Additional steps are 


# Left as notes for further updates
1) Fork this repo and then clone it locally; although cloning it locally straight from the ot4i repo would allow building locally, for the pipeline itself to work some of the files need to be updated. The source also needs to be accessible to the IBM Cloud Kubernetes workers, and a public github repo forked from this one is the easiest way to do this. Cloning can be achieved with the git command line, or via the ACE v12 toolkit; the ACE v12 product can be downloaded from [the IBM website](https://www.ibm.com/marketing/iwm/iwm/web/pickUrxNew.do?source=swg-wmbfd).
2) Acquire an IBM Cloud account and create a Kubernetes cluster called "aceCluster", a Docker registry, and a DB2 on Cloud instance. More info in [cloud resources description](demo-infrastructure/cloud-resources.md).
3) Build the pre-req docker images and create the required credentials; see instructions in the [demo-infrastructure](demo-infrastructure) and [tekton/minimal-image-build](tekton/minimal-image-build) directories.
4) Component testing relies on the same DB2 on Cloud instance as the eventual application image; this is not a best practice, but does keep the demo simpler to get going, and so getting the DB2 instance credentials set up in Kubernetes and/or locally is necessary for the component tests.
5) Try running the pipeline using the instructions in the [tekton](tekton) directory.
6) Optionally, enable GitHub actions; this requires a GitHub instance that supports actions (not all Enterprise variants do), and credit enough to run the actions.
