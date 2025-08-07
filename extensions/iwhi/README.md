# IBM webMethods Hybrid Integration 

IWHI allows webMethods workflows to call ACE flows via private network connections
to ACE integration servers, and this allows the creation of hybrid solutions where
the Internet-facing REST APIs are hosted in the cloud while the database accesses
happen in an on-prem ACE flow (container or integration node).

## Solution overview

![solution picture](/demo-infrastructure/images/iwhi-diagram.png)

- ACE flows described and deployed elsewhere. They could be running in containers
  (ordinary or CP4i) or an integration node, but the servers must be configured 
  with an IWHI switchclient.json so that the callable flows are visible to IWHI.
- wM workflows deployed from this directory using GitHub Actions.

## Initial artifact creation

The workflows were created in an IWHI project and then exported using the `wmiocli` tool
from https://github.com/trevor-dolby-at-ibm-com/webmethods-io-integration-apicli (forked 
from the [original repo](https://github.com/ibm-wm-transition/webmethods-io-integration-apicli) 
to fix IWHI authentication issues) 
```
node wmiocli.js -d dev2299223.a-vir-r1.int.ipaas.automation.ibm.com -k APIkey project-export ACEDemoTeaAPI ACEDemoTeaAPI-export.zip
```
The exported project is stored as ACEDemoTeaAPI-export.zip in this directory, and can 
be deployed with the [IWHI workflow deploy](/.github/workflows/iwhi-workflows.yml) GitHub Action.

## Deploy

Combination of manual and automated steps, with automation for workflow and ACE updates.

![pipeline picture](/demo-infrastructure/images/iwhi-diagram-with-pipeline.png)

The automated steps use the wM REST API (described at https://github.com/ibm-wm-transition/webmethods_io_int_cicd/blob/main/apis/wMIO_OpenAPI_Spec_v3.yaml)
to deploy artifacts using curl.

- The `ACEDemoTeaAPI` webMethods project does not have to exist before the deploy can start,
  but the ACE callable flows must be visible to the IWHI instance before the deploy. This
  part relies on the on-prem pipeline having deployed the flows and configuration correctly, 
  and only needs to be done once. The `TeaCallableApplicationV2` application should have 
  `getIndex` and `postIndex` made available to the project, as these will be needed
  by the workflows and will be visible in the "Callable flows" tab of the project.
- The `ACEDemoTeaAPI` project with the TeaGetIndex and TeaPostIndex workflows can be 
  deployed automatically using the [IWHI workflow deploy](/.github/workflows/iwhi-workflows.yml)
  action, which will import the project into the configured instance.
- After the workflows have been imported with the project, the REST APIs should be 
  operational and can be viewed in the UI (or invoked via curl). The result should 
  look as follows for `/index`:

  ![POST](/demo-infrastructure/images/rest-api-POST.png)

  and for `/index/{id}`:

  ![GET](/demo-infrastructure/images/rest-api-GET.png)


### Configuration for the "IWHI workflow deploy" action

The GitHub repo "Actions secrets and variables" settings page can be used to create
secrets and environment variables that enable the automated deploy.

*Repository secrets*

`IWHI_X_INSTANCE_API_KEY` can be created by following the instructions at
https://www.ibm.com/docs/en/wm-integration-ipaas?topic=reference-authenticating-api-requests.

*Repository variables*

`IWHI_WM_HOSTNAME` should be set to the base address of the instance (e.g., 
"dev2299223.a-vir-r1.int.ipaas.automation.ibm.com").

## Issues with missing capabilities

Errors of the form
```
{"error":{"message":"SAP® ERP is not available in this tenant.","code":400,"errorSource":{"errorCode":"API_000","requestID":"4cb1da4ec743b6eaf115d899a5c63dfa"}}}
```
may occur if the destination instance does not have the SAP capabilities and the original
instance did have SAP available. The projects in this repo were created on an instance
without SAP and so the import should not hit this issue, but anyone trying to replicate
the steps to build the project may see this if they export from a more-functional instance.

Note that this error can occur even though the webMethods flows in this repo do not use SAP. 

## Creating the REST APIs manually

The REST APIs may be created manually using the "Create from scratch/Design new API" 
approach described at https://www.ibm.com/docs/en/wm-integration-ipaas?topic=apis-creating-rest 
(the other methods do not allow workflows to be attached to the operations). The resource names
must be `/index/{id}` for GET and `/index` for POST, and should only need to be created once.

The result should look as follows for `/index`:

![POST](/demo-infrastructure/images/rest-api-POST.png)

and for `/index/{id}`:

![GET](/demo-infrastructure/images/rest-api-GET.png)
