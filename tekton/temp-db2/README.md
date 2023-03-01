# Pipeline using temporary DB2

Modifies the main pipeline to use a separate DB2 container for each pipeline run, creating
and deleting the container as part of the build.

![Pipeline overview](temp-db2-pipeline-20230301.png)

The rest of the pipeline remains unchanged, with only the `maven-ace-build` task changing.

## Overview

The modified `maven-ace-build` task adds three new steps in order to run new DB2 database
for each pipeline run. Running a new database each time ensures that the test results are
repeatable and not influenced by previous test runs, but also requires more cluster resources
as a new database must be created and started each time.

As well as starting the database, the pipeline must stop it to free resources. This happens in
three ways:
- Explicit shutdown after testing is complete
- A timer running inside the container shuts the database down after 30 minutes
- A container left from a previous run is deleted when a new pipeline run starts

Once the database is up and running, the TEAJDBC policy is customized to point to the IP address
of the DB2 pod and (along with the userid/password) provided to the test. The task steps create
files that mimic the Kubernetes secret format, and the [init-creds](/demo-infrastructure/init-creds.sh)
script picks them up and uses them to configure the server.

### Task step details

#### start-db2
Calls [start-db2-container.sh](start-db2-container.sh):
- Checks for previously-started containers and deletes them
- Starts the DB2 container for this pipeline run
- Launches the shutdown timer script in the new container

#### wait-for-db2
Calls [wait-for-db2-container.sh](wait-for-db2-container.sh):
- Waits for the database container log to say "Setup has completed"
- Creates the credentials in /work/jdbc to be picked up by init-creds.sh

#### stop-db2
Calls [stop-db2-container.sh](stop-db2-container.sh):
- Deletes the DB2 container


## Advantages of a per-run database

## Disadvantages of a per-run database

## Getting started

```
kubectl apply -f tekton/temp-db2/14-maven-ace-build-temp-db2-task.yaml
```

## Notes

The main tekton service account has been adjusted to allow container logs to be queried, which is 
needed in order to determin ewhen the database has finished starting up.
