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

## Deploy

Combination of manual and automated steps, with automation for workflow and ACE updates.

![pipeline picture](/demo-infrastructure/images/iwhi-diagram-with-pipeline.png)

- A webMethods project must exist before the deploy can start, and the ACE callable
  flows should be added manually (assuming the ACE flows are deployed and visible to
  IWHI). This part relies on the on-prem pipeline having deployed the flows and 
  configuration correctly, and only needs to be done once. The `TeaCallableApplicationV2`
  application should have `getIndex` and `postIndex` made available to the project.
- The `TeaGetIndex` and `TeaPostIndex` workflows can be deployed automatically using
  the [IWHI workflow deploy](/.github/workflows/iwhi-workflows.yml) action, which
  will import the two workflows into an existing project.
- After the workflows have been imported into the project, the REST APIs must be 
  created manually using the "Create from scratch/Design new API" approach described
  at https://www.ibm.com/docs/en/wm-integration-ipaas?topic=apis-creating-rest (the
  other methods do not allow workflows to be attached to the operations). The resource
  names must be `/index/{id}` for GET and `/index` for POST, and should only need to
  be created once.

  The result should look as follows for `/index`:

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

`IWHI_WORKFLOW_PROJECT` should be set to an existing webMethods project (e.g.,
"TDolbyThirdProject").