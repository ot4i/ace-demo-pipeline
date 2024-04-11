#!/bin/bash

# Assumes the current shell has oc in PATH, is logged in, and has
# the correct namespace set as default.

# We might be run from the root of the repo or from the subdirectory
export YAMLDIR=`dirname $0`

set -e # Exit on error
set -x # Show what we're doing


oc apply -f ${YAMLDIR}/cp4i-scc.yaml
oc apply -f ${YAMLDIR}/service-account-cp4i.yaml
oc adm policy add-scc-to-user cp4i-scc -n cp4i -z cp4i-tekton-service-account
oc apply -f ${YAMLDIR}/12-ibmint-cp4i-build-task.yaml
oc apply -f ${YAMLDIR}/13-component-test-in-cp4i-task.yaml
oc apply -f ${YAMLDIR}/22-deploy-to-cp4i-task.yaml
oc apply -f ${YAMLDIR}/cp4i-pipeline.yaml

set +x
echo "Success; the pipeline can now be run after the *-run.yaml files are customized."
echo "Use ${YAMLDIR}/cp4i-pipeline-run.yaml to run the CP4i pipeline. "
echo
echo "Example command sequence to run the pipeline and show the Tekton logs:"
echo
echo "oc create -f ${YAMLDIR}/cp4i-pipeline-run.yaml ; tkn pr logs -L -f"
