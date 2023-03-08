# Docker images for build pipelines to use

Building on top of ace-minimal (see https://github.com/trevor-dolby-at-ibm-com/ace-docker/tree/master/experimental/ace-minimal
for more information) to create a builder image that contains build-time code that should not be pushed into the final application.

- ace-minimal-build is used for running the Tekton pipeline for the demo application build and also for running Jenkins
  pipeline steps. Normally built using the ace-minimal-build-image-build-and-push task in the "tekton/minimal-image-build"
  directory in this repo, as that job will build and push in the cloud, but this image can be built locally if Jenkins
  is the preferred build tool.
