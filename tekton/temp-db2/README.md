# Pipeline using temporary DB2

Modifies the main pipeline to use a separate DB2 container for each pipeline run, creating
and deleting the container as part of the build.

![Pipeline overview](temp-db2-pipeline-20230301.png)

The rest of the pipeline remains unchanged, with only the `maven-ace-build` task changing.

```
kubectl apply -f tekton/temp-db2/14-maven-ace-build-temp-db2-task.yaml
```


service account adjusted
