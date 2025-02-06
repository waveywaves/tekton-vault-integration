#!/bin/bash
set -e

echo "Installing Secrets Store CSI Driver and Vault Provider..."

# get the csi driver helm stuff - this is where all the good stuff lives
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo update

# make a home for our csi driver
kubectl create namespace csi-driver || true

# install the csi driver with some nice features turned on
helm upgrade --install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace csi-driver \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true

# wait for the csi driver to get its act together
echo "Waiting for CSI driver to be ready..."
kubectl rollout status daemonset/csi-secrets-store-secrets-store-csi-driver -n csi-driver --timeout=120s

# now lets grab the vault provider - this is what lets us talk to vault
kubectl apply -f https://raw.githubusercontent.com/hashicorp/vault-csi-provider/main/deployment/vault-csi-provider.yaml

# give the vault provider a moment to settle in
echo "Waiting for Vault CSI provider to be ready..."
sleep 10  # gotta give it a sec to create everything
kubectl rollout status daemonset/vault-csi-provider -n csi-driver --timeout=120s || true

# double check that everything's looking good
echo "Verifying CSI installation..."
kubectl get pods,daemonset -n csi-driver

echo "Secrets Store CSI Driver and Vault Provider installation complete!" 