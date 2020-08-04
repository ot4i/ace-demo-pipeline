# Infrastructure for ACE pipeline demo

Various applications, scripts, and Dockerfiles for the pipeline demo. These files are 
not specific to this application, and would normally reside elsewhere and be shared by 
multiple application projects, but the demo is more self-contained if we keep them here.

## Message flow recording

com.ibm.ot4i.ace.pipeline.demo.infrastructure.RecordOneFlow is used to record message trees 
at each node transition in a message flow. It uses the Integration API (formerly CMPAPI) to 
make REST calls to a running server to start recording data and retrieve the data when enough 
messages have been sent through the flow, and these messages can then be used by unit tests 
(using the injection APIs) to drive individual nodes via scaffold flows; see the TeaTests 
project in this repo for examples.

The recorded data is placed into files in a specific directory (easily modified) in sequence 
order; see comments in the recorder application for more detail. This directory is an Eclipse 
Java project that can be imported (via egit) into the ACE toolkit.

## Docker images

The docker directory contains build files for the two docker images needed for the pipeline 
demo to work. The ace-jenkins-server image runs the Jenkins server for the pipeline, and the
pipeline-travis-build image is pulled by Travis and used to run build and unit tests as part
of the CI build.
