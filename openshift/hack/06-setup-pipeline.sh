#!/bin/bash
set -e

echo "Setting up OpenShift Pipeline with Vault integration..."

# Set privileged security context for the namespace
oc label namespace tekton-vault pod-security.kubernetes.io/enforce=privileged --overwrite

# Grant CSI driver permissions to create tokens
oc create clusterrolebinding csi-token-creator \
    --clusterrole=system:node \
    --serviceaccount=csi-driver:secrets-store-csi-driver || true

# apply all manifests
oc apply -f openshift/config/pipeline/01-pipeline-sa.yaml
oc apply -f openshift/config/pipeline/02-secret-provider-class.yaml
oc apply -f openshift/config/pipeline/03-task.yaml
oc apply -f openshift/config/pipeline/04-pipeline.yaml
oc apply -f openshift/config/pipeline/05-pipeline-run.yaml

echo "Waiting for pipeline run to complete..."
oc wait --for=condition=succeeded pipelinerun/vault-secret-pipeline-run -n tekton-vault --timeout=120s

echo "Pipeline run logs:"
if ! tkn pipelinerun logs vault-secret-pipeline-run -n tekton-vault -f; then
    echo "Failed to get pipeline logs. Please check the pipeline status manually."
    exit 1
fi

echo "Pipeline setup and execution complete!" 