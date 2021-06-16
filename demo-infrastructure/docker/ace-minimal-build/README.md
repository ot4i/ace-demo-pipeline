# CI Docker image

Used by the pipeline in this repo to run the ACE commands within a CI or other pipeline build.

Built on top of ace-minimal:12.0.1.0-alpine (in a registry of your choice and built from https://github.com/ot4i/ace-docker/tree/master/experimental/ace-minimal) but will be pushed to the same registry via the Tekton pipelines in tekton/minimal-image-build in this repo.
