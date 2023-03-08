# CI Docker image

Used by the pipeline in this repo to run the ACE commands within a CI or other pipeline build.

Built on top of ace-minimal:12.0.7.0-alpine (in a registry of your choice and built from 
https://github.com/trevor-dolby-at-ibm-com/ace-docker/tree/master/experimental/ace-minimal)
but will be pushed to the same registry via the Tekton pipelines in tekton/minimal-image-build
in this repo if using Tekton.

For Jenkins build purposes, this image is needed locally and should be built with
```
docker build -t ace-minimal-build:12.0.7.0-alpine .
```
after building ace-minimal:12.0.7.0-alpine from the ace-docker repo (linked above).
