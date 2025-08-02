# App Connect Designer

App Connect Designer hosted in App Connect as a Service (ACEaaS) allows Designer
workflows to call ACE flows via private network connections to ACE integration 
servers, and this allows the creation of hybrid solutions where the Internet-facing
REST APIs are hosted in the cloud while the database accesses happen in an on-prem 
ACE flow (container or integration node). ACE Designer flows can also run in IBM
webMethods Hybrid Integration, as that includes the required ACEaaS capabilities.

## Solution overview

![solution picture](/demo-infrastructure/images/aceaas-designer-diagram.png)

- ACE flows described and deployed elsewhere. They could be running in containers
  (ordinary or CP4i) or an integration node, but the servers must be configured 
  with an ACEaaS switchclient.json so that the callable flows are visible to ACEaaS.
- ACEaaS REST API project deployed from this directory using GitHub Actions.

## Initial artifact creation

The workflows were created in a Designer authoring editor in ACEaaS and tested with
callable flows running in CP4i containers on-prem. The flows were then exported from
the ACEaaS cloud service, stored as TeaAPI.bar in this directory, and can be deployed 
with the [ACEaaS Designer flows deploy](/.github/workflows/aceaas-designer.yml) GitHub Action.

Note that this pipeline deploys the Designer flows as a BAR file, which does not 
load the flows into the Designer Authoring experience: the flows will run successfully,
but will not be editable nor appear in the ACEaaS Dashboard.

## Deploy

Combination of automated steps, with automation for Designer and ACE updates.

![pipeline picture](/demo-infrastructure/images/aceaas-designer-diagram-with-pipeline.png)

The automated steps use the ACEaaS REST API (described at https://www.ibm.com/docs/en/app-connect/saas?topic=overview-openapi-document)
to deploy artifacts using curl.

- The Designer project is deployed to an App Connect runtime that does not need to 
  exist at the start of the process, as it will be created as needed. The switch client
  connection will be established automatically from the Designer flows, using the
  `default-switch-server-privatenetworkagent` configuration. 
- The ACE callable flows must be visible to the ACEaaS instance before the Designer deploy. 
  This can be achieved by deploying the ACE flows using one of the various deployment targets
  in this repo (Kubernetes containers (including CP4i), Integration Nodes, or ACEaaS again)
  and ensuring the ACE server is connected to the ACEaaS switch.

Testing can be performed with curl, or by using the ACEaaS UI to invoke the GET or POST
methods using the "try it" tab on the REST API itself.

### Configuration for the "ACEaaS Designer flows deploy" action

The GitHub repo "Actions secrets and variables" settings page can be used to create
secrets and environment variables that enable the automated deploy.

*Repository secrets*

See [https://www.ibm.com/docs/en/app-connect/saas?topic=overview-accessing-api](https://www.ibm.com/docs/en/app-connect/saas?topic=overview-accessing-api)
for details on how to create the correct credentials, and then set the following:

`APPCON_INSTANCE_ID` is the instance identifier (similar to `2vkpa0udw` or `dev2299223`)

`APPCON_CLIENT_ID` is the client ID created from the "Public API credentials" section of the ACEaaS dashboard 

`APPCON_CLIENT_SECRET` is the client secret created from the "Public API credentials" section of the ACEaaS dashboard 

`APPCON_API_KEY` is the API key created from the ACEaaS dashboard 

*Repository variables*

`APPCON_ENDPOINT` should be set to the base address of the instance regiuon, prefixed with
"api" (e.g., "api.a-vir-c1.appconnect.ipaas.automation.ibm.com"). See the 
[API docs](https://www.ibm.com/docs/en/app-connect/saas?topic=overview-openapi-document)
for details.

`APPCON_DEPLOY_PREFIX` should be set to a unique prefix, such as "tdolby" or "testflows".