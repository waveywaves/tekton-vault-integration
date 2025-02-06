#!/bin/bash
set -e

echo "Installing Vault..."

# hashicorp repo
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# make a cozy namespace for vault to live in
kubectl create namespace vault || true

# dev mode for testing - dont do this in prod
helm upgrade --install vault hashicorp/vault \
  --namespace vault \
  --set "server.dev.enabled=true" \
  --set "server.dev.devRootToken=root"

# give vault a sec to wake up
echo "Waiting for Vault pod to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n vault --timeout=120s

# make sure vault's feeling good
echo "Verifying Vault installation..."
kubectl get pods -n vault

echo "Vault installation complete!" 