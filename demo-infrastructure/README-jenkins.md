# Jenkins pipeline

Used to run the pipeline stages via Jenkins. Relies on an existing integration node being available with the JDBC
credentials having been set up, and will run on Windows or via docker on Unix platforms.

![Pipeline overview](ace-nodes-testing-jenkins.png)

## Running Jenkins

Jenkins can be run from a command line as follows once downloaded:
```
java -jar jenkins.war --httpPort=8080
```
See https://www.jenkins.io/doc/pipeline/tour/getting-started/ for details and download locations.

## Getting started with the pipeline

Forking this repo is advisable, as then it can be modified to use the correct database location
and integration node. In the fork, the following values should be changed in either Jenkinsfile
or Jenkinsfile.windows depending on which platform is used:
- databaseName
- serverName
- portNumber
- integrationNodeHost
- integrationNodePort
- integrationServerName

Once those values have been updated, then the pipeline can be constructed, but it may be a good
idea to change "GitHub API usage" under "Configure System" in the Jenkins settings as otherwise
messages such as the following may appear regularly:
```
17:07:37 Jenkins-Imposed API Limiter: Current quota for Github API usage has 52 remaining (1 over budget). Next quota of 60 in 58 min. Sleeping for 4 min 9 sec.
17:07:37 Jenkins is attempting to evenly distribute GitHub API requests. To configure a different rate limiting strategy, such as having Jenkins restrict GitHub API requests only when near or above the GitHub rate limit, go to "GitHub API usage" under "Configure System" in the Jenkins settings.
```

To create the pipeline (and following the Jenkins pipeline tour instructions), a "multibranch 
pipeline" should be created and pointed at the github repo. For Windows users, the pipeline 
should be configured to look for `Jenkinsfile.windows`, while the default of `Jenkinsfile` is
appropriate for other platforms.

Once the pipeline has been created and branches configured, the JDBC credentials need to be provided
as a username/password credential called `CT_JDBC`. The same credentials must be provided to the 
destination integration node along with a JDBC policy called TEAJDBC. Using mqsisetdbparms for the
credentials would look as follows
```
mqsisetdbparms <integration node> -n jdbc::tea -u <db2user> -p <db2password>
```
and the policy should look like
```
<?xml version="1.0" encoding="UTF-8"?>
<policies>
  <policy policyType="JDBCProviders" policyName="TEAJDBC" policyTemplate="DB2_91_Linux">
    <databaseName>BLUDB</databaseName>
    <databaseType>DB2 Universal Database</databaseType>
    <databaseVersion>11.5</databaseVersion>
    <type4DriverClassName>com.ibm.db2.jcc.DB2Driver</type4DriverClassName>
    <type4DatasourceClassName>com.ibm.db2.jcc.DB2XADataSource</type4DatasourceClassName>
    <connectionUrlFormat>jdbc:db2://[serverName]:[portNumber]/[databaseName]:user=[user];password=[password];</connectionUrlFormat>
    <connectionUrlFormatAttr1></connectionUrlFormatAttr1>
    <connectionUrlFormatAttr2></connectionUrlFormatAttr2>
    <connectionUrlFormatAttr3></connectionUrlFormatAttr3>
    <connectionUrlFormatAttr4></connectionUrlFormatAttr4>
    <connectionUrlFormatAttr5></connectionUrlFormatAttr5>
    <serverName>19af6446-6171-4641-8aba-9dcff8e1b6ff.c1ogj3sd0tgtu0lqde00.databases.appdomain.cloud</serverName>
    <portNumber>30699</portNumber>
    <jarsURL></jarsURL>
    <databaseSchemaNames>useProvidedSchemaNames</databaseSchemaNames>
    <description></description>
    <maxConnectionPoolSize>0</maxConnectionPoolSize>
    <securityIdentity>tea</securityIdentity>
    <environmentParms>sslConnection=true</environmentParms>
    <jdbcProviderXASupport>false</jdbcProviderXASupport>
    <useDeployedJars>true</useDeployedJars>
  </policy>
</policies>
```
and be deployed to the default policy project for the integration server specified above.

## Running the pipeline and validating the results

Assuming the pipeline parameters have been modified in the Jenkinsfile, the pipeline can be run
using "Build with Parameters" on the desired branch. This should start the pipeline, which will
then pull the source down, compile and test it, and then deploy it to the integration node.

Once the pipeline has completed successfully, the application can be tested by using a browser
or curl to access the application API endpoint at http://localhost:7800/tea/index/1 (assuming a
node without MQ on the default HTTP per-server listener port), which is likely to return null
values unless there is data in the database already:
```
C:\>curl http://localhost:7800/tea/index/1
{"name":null,"id":"1"}
```

To add tea to the index, curl can be used:
```
curl -X POST --data '{"name": "Assam", "strength": 5}' http://localhost:7800/tea/index
```

## Possible enhancements

The pipeline could use a configuration file to contain the DB2 database location and the location of the 
integration node, all of which are currently parameters for the pipeline itself.
