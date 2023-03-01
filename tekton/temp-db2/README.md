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

As well as starting the database, it must be stopped to free resources. This happens in
three ways:
- Explicit shutdown after testing is complete
- A timer running inside the container shuts the database down after 30 minutes
- A container left from a previous run is deleted when a new pipeline run starts


The extra task steps are as follows:
- start-db2, which creates the container and 

## Advantages

## Disadvantages

## Getting started

```
kubectl apply -f tekton/temp-db2/14-maven-ace-build-temp-db2-task.yaml
```

service account adjusted
