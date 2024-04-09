#!/bin/bash

# Assumes the current shell has kubectl in PATH, is logged in, and has
# the correct namespace set as default. The cluster is also assumed to
# have Tekton installed and a service account created for the pipeline.

# We might be run from the root of the repo or from the subdirectory
export YAMLDIR=`dirname $0`

set -e # Exit on error
set -x # Show what we're doing
kubectl apply -f ${YAMLDIR}/01-ace-minimal-image-build-and-push-task.yaml
kubectl apply -f ${YAMLDIR}/02-ace-minimal-build-image-build-and-push-task.yaml
kubectl apply -f ${YAMLDIR}/ace-minimal-build-image-pipeline.yaml
kubectl apply -f ${YAMLDIR}/ace-minimal-image-pipeline.yaml

set +x
echo "Success; the pipeline can now be run after the *-run.yaml files are customized."
echo "Use ${YAMLDIR}/ace-minimal-build-image-pipeline-run.yaml to build both images, or ${YAMLDIR}/ace-minimal-image-pipeline-run.yaml for only ace-minimal"
echo
echo "Example command sequence to run the pipeline and show the Tekton logs:"
echo
echo "kubectl apply -f ${YAMLDIR}/ace-minimal-build-image-pipeline-run.yaml ; tkn pr logs ace-minimal-build-image-pipeline-run-1 -f"