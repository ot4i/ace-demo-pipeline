# Pipeline scripts

Used to run the pipeline stages; scripts allow Jenkins and Travis to stay in sync without
manual effort, and also allow all change history to exist in one place (this repo) instead
of being split between this repo and Jenkins.

The four stage scripts run actual commands:
- build-and-ut.sh
- component-test.sh
- preprod-bar-build.sh
- preprod-deploy-and-test.sh

There are also utility scripts to enable the other scripts to be more compact:
- force-failure-on-junit-fail.sh
- start-server-and-run-tests.sh
- start-server.sh

The "force failure" script is needed due to the difficulty of getting Blue Ocean to recognise 
when JUnit tests have failed without accidentally stopping the JUnit results from being uploaded
to the Jenkins server: build-and-ut.sh notices the JUnit failures, creates a special file and
returns 0 to Blue Ocean, which uploads the JUnit results and then calls force-failure-on-junit-fail.sh
to check the special file and fail the build if anything went wrong earlier.

preprod-container is used by preprod-bar-build.sh to create the Docker image for the ACE application.
