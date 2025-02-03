#!/bin/bash
set -e

echo "Installing Vault..."

# Add HashiCorp Helm repository
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Create namespace for Vault
kubectl create namespace vault || true

# Install Vault using Helm
helm upgrade --install vault hashicorp/vault \
  --namespace vault \
  --set "server.dev.enabled=true" \
  --set "server.dev.devRootToken=root"

# Wait for Vault pod to be ready
echo "Waiting for Vault pod to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n vault --timeout=120s

# Verify installation
echo "Verifying Vault installation..."
kubectl get pods -n vault

echo "Vault installation complete!" 