# ACEaaS pipelines and configurations

ACE-as-a-Service is built on the Cloud Pak for Integration (CP4i) and uses the same 
set of artifacts to run ACE flows, so the pipelines will create the same set of 
configurations to run the Tea REST application. Details on the various configuration
types can be found [in the ACEaaS docs](https://www.ibm.com/docs/en/app-connect/containers_cd?topic=dashboard-configuration-types-integration-servers-integration-runtimes)
but the key artifacts built for this application are as follows:

- A BAR file containing the Tea REST application, associated shared libraries, JDBC
  driver, and any other code needed for successful operation. ACEaaS uses the same
  BAR format as integration nodes; there is only one ACE BAR format.
- A set of configurations for the various credentials and service locations:
  - [policy project](https://www.ibm.com/docs/en/app-connect/containers_cd?topic=runtimes-policy-project-type)
    for the JDBCProviders policy used for database access.
  - [setdbparms.txt](https://www.ibm.com/docs/en/app-connect/containers_cd?topic=runtimes-setdbparmstxt-type)
    configuration for the JDBC username/password.
  - [server.conf.yaml](https://www.ibm.com/docs/en/app-connect/containers_cd?topic=runtimes-serverconfyaml-type)
    configuration to specify the JDBC policy project as the default for the server.
- An [Integration Runtime](https://www.ibm.com/docs/en/app-connect/containers_cd?topic=resources-integration-runtime-reference)
  that references the BAR file and various configurations; this artifacts causes ACEaaS to
  start an IntegrationServer in a container.

![ACEaaS pipelines](/demo-infrastructure/images/aceaas-pipeline-overview.png)

## ACEaaS API

The pipelines will call the [ACE-as-a-Service API](https://www.ibm.com/docs/en/app-connect/saas?topic=information-api-overview) 
to create and deploy the various artifacts, and require credentials to be able to do so.
These can be created using the ACEaaS console and provided to the pipeline as credentials:

- Endpoint URL (similar to `api.p-vir-c1.appconnect.automation.ibm.com`)
- Instance identifier (similar to `2vkpa0udw`)
- Client ID and client secret, created from the "Public API credentials" section of the ACEaaS dashboard 
  (see URL of the form https://2vkpa0udw-dashboard.p-vir-c1.appconnect.automation.ibm.com/settings?tab=credentialsTab)
- API key created from the ACEaaS dashboard (see URL of the form https://2vkpa0udw-dashboard.p-vir-c1.appconnect.automation.ibm.com/management/apikeys)

See [https://www.ibm.com/docs/en/app-connect/saas?topic=overview-accessing-api](https://www.ibm.com/docs/en/app-connect/saas?topic=overview-accessing-api) for
further instructions on how to create the correct credentials.

## ACEaaS API rate limits

The API has a limit of 100 calls per hour (at the time of writing) which could be exhausted 
quickly if the configurations are recreated every time, and so the configuration creation is
normally only run when needed (such as the first time the application is being deployed).

Note that the API call to acquire a token counts as part of the limit, so each application 
deployment uses two calls (one for the token and the other to deploy the BAR file). It might
be possible to securely store the token between pipeline runs in some scenarios, but care
must be taken if this is attempted: the token should be kept secret, and ideally stored in a
secure vault, but the tokens also expire every 12 hours and so need to be refreshed.

The examples in this repo acquire a new token every time to avoid having to solve this issue,
using pipeline-provided secure storage (Kubernetes secrets, Jenkins credentials, etc) to 
ensure the API keys are kept securely.

The API rate limit also prevents polling for the application to (re)start successfully, so the
pipelines complete after updating the BAR file (or after creating the initial configuration)
rather than completing when the application is actually running with the built artifacts.

