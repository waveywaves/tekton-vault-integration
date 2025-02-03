#!/bin/bash
set -e

echo "Setting up Tekton pipeline with Vault integration..."

# Apply all manifests
kubectl apply -f ../config/pipeline/01-pipeline-sa.yaml
kubectl apply -f ../config/pipeline/02-secret-provider-class.yaml
kubectl apply -f ../config/pipeline/03-task.yaml
kubectl apply -f ../config/pipeline/04-pipeline.yaml
kubectl apply -f ../config/pipeline/05-pipeline-run.yaml

echo "Waiting for pipeline run to complete..."
kubectl wait --for=condition=succeeded pipelinerun/vault-secret-pipeline-run --timeout=120s

echo "Pipeline run logs:"
tkn pipelinerun logs vault-secret-pipeline-run -f

echo "Pipeline setup and execution complete!" 