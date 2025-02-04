#!/bin/bash
set -e

echo "Installing OpenShift Pipelines..."

# Create the OpenShift Pipelines subscription
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-pipelines-operator
  namespace: openshift-operators
spec:
  channel: latest
  name: openshift-pipelines-operator-rh
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

# Wait for the operator to be ready
echo "Waiting for OpenShift Pipelines operator to be ready..."
while ! oc get deployment openshift-pipelines-operator -n openshift-operators &> /dev/null; do
    echo "Waiting for operator deployment..."
    sleep 5
done

# Wait for the deployment to be ready
oc wait --for=condition=available deployment/openshift-pipelines-operator -n openshift-operators --timeout=300s

# Verify installation
echo "Verifying OpenShift Pipelines installation..."
oc get tektonconfig
oc get pods -n openshift-pipelines

echo "OpenShift Pipelines installation complete!" 