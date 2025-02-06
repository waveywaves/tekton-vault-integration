#!/bin/bash
set -e

echo "Installing Vault..."

helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

oc create namespace vault || true

helm upgrade --install vault hashicorp/vault \
  --namespace vault \
  -f ../config/vault/values.yaml

echo "Waiting for Vault pod to be ready..."
oc wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n vault --timeout=120s

echo "Verifying Vault installation..."
oc get pods -n vault

echo "Vault installation complete!" 