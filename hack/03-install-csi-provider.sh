#!/bin/bash
set -e

echo "Installing Secrets Store CSI Driver and Vault Provider..."

# Add Secrets Store CSI Driver Helm repository
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo update

# Create namespace for CSI driver
kubectl create namespace csi-driver || true

# Install Secrets Store CSI Driver
helm upgrade --install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace csi-driver \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true

# Wait for CSI driver DaemonSet to be ready
echo "Waiting for CSI driver to be ready..."
kubectl rollout status daemonset/csi-secrets-store-secrets-store-csi-driver -n csi-driver --timeout=120s

# Install Vault CSI Provider
kubectl apply -f https://raw.githubusercontent.com/hashicorp/vault-csi-provider/main/deployment/vault-csi-provider.yaml

# Wait for Vault CSI provider DaemonSet to be ready
echo "Waiting for Vault CSI provider to be ready..."
sleep 10  # Give some time for the DaemonSet to be created
kubectl rollout status daemonset/vault-csi-provider -n csi-driver --timeout=120s || true

# Verify installation
echo "Verifying CSI installation..."
kubectl get pods,daemonset -n csi-driver

echo "Secrets Store CSI Driver and Vault Provider installation complete!" 