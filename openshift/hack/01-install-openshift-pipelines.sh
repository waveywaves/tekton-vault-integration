#!/bin/bash
set -e

echo "Installing OpenShift Pipelines..."

oc apply -f openshift/config/operators/pipeline-operator.yaml

echo "Waiting for OpenShift Pipelines operator to be ready..."
while ! oc get deployment openshift-pipelines-operator -n openshift-operators &> /dev/null; do
    echo "Waiting for operator deployment..."
    sleep 5
done

oc wait --for=condition=available deployment/openshift-pipelines-operator -n openshift-operators --timeout=300s

echo "Verifying OpenShift Pipelines installation..."
oc get tektonconfig
oc get pods -n openshift-pipelines

echo "OpenShift Pipelines installation complete!" 