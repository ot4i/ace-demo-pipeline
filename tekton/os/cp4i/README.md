# CP4i pipeline

This pipeline is similar to the main project pipeline, but is designed to work with the Cloud Pak for Integration (CP4i) 
and uses the App Connect Enterprise certified containers for runtime. It also runs component tests in a CP4i container to
allow JDBC connections to be tested using the same CP4i configurations used by the deployed application itself.

![Pipeline overview](images/cp4i-pipeline.png)

## Container builds

The pipeline creates the main applicaiton image first, and then builds the component test image on top of the first image.
Kaniko is used to build both images in the pipeline, with Maven building the applications and libraries.

![Container images](images/cp4i-container-images.png)

## Component testing

The component testing itself relies on the operator support code (runaceserver) to create the correct policies and
credentials from the configurations provided. This allows the component tests to run with the same setup as the application
itself, ensuring the tests are providing useful results.

![work directory](images/cp4i-work-dir.png)

The test run strategy is as follows:

- Create a CR with MQSI_PREVENT_CONTAINER_SHUTDOWN set plus the database credentials configurations (and any other needed configurations) using the second custom image (the one with the tests), and let it start up.
- Stop the running server with kill -INT 1 (via kubectl exec) to cause the runaceserver code to shut the server down and then wait (due to MQSI_PREVENT_CONTAINER_SHUTDOWN  being set).
- Once the server is stopped, run a new server (using kubectl exec or whatever) that specifies the correct test project and any test options (like IntegrationServer -w /home/aceuser/ace-server --test-project SomeTestProject --start-msgflows false)
- Collect the output and return code from kubectl exec as usual, allowing the pipeline to stop on failed tests.
- Delete the CR, and then send another kill -INT 1 to make the runaceserver code exit.

Note that this splits responsibilities between the ACE operator (create the work directory and run the initial server) and the
ACE product itself (run the tests and report the results); the operator support code in the container does not know anything
about running tests.

## Pipeline setup and run
