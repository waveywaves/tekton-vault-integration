#!/bin/bash
set -e

echo "Installing Vault w/ Helm..."

helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

oc create namespace vault || true

oc apply -f openshift/config/vault/scc.yaml || true
oc adm policy add-scc-to-user vault-scc -z vault -n vault || true

helm upgrade --install vault hashicorp/vault \
  --namespace vault \
  --set "global.openshift=true" \
  -f openshift/config/vault/values.yaml

echo "Waiting for Vault pod to be ready..."
oc wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n vault --timeout=300s

echo "Verifying Vault installation..."
oc get pods -n vault

echo "Vault installation complete!" 