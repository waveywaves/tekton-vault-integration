#!/bin/bash
set -e

echo "Installing Tekton Pipelines..."

# grab the latest Tekton stuff from upstream
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

echo "Waiting for Tekton pods to be ready..."
kubectl wait --for=condition=ready pod -l app=tekton-pipelines-controller -n tekton-pipelines --timeout=120s
kubectl wait --for=condition=ready pod -l app=tekton-pipelines-webhook -n tekton-pipelines --timeout=120s

# make sure everything's running smoothly
echo "Verifying Tekton installation..."
kubectl get pods -n tekton-pipelines

echo "Tekton Pipelines installation complete!" 