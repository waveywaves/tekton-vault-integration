#!/bin/bash
set -e

echo "Installing Secrets Store CSI Driver and Vault Provider..."

# create our namespaces
oc create namespace csi-driver || true
oc create namespace csi || true

# set up the privileged scc first - csi driver needs this to work
oc apply -f openshift/config/csi/csi-scc.yaml

# give the service account access to our privileged scc
oc adm policy add-scc-to-user csi-privileged-scc -z secrets-store-csi-driver -n csi-driver || true

# add the helm repo for the csi driver
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo update

# install the csi driver - this needs privileged access
helm upgrade --install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace csi-driver \
  --set linux.privileged=true \
  --set linux.securityContext.privileged=true \
  -f openshift/config/csi/values.yaml

echo "Waiting for CSI driver to be ready..."
oc rollout status daemonset/csi-secrets-store-secrets-store-csi-driver -n csi-driver --timeout=120s

# now set up the vault provider
oc apply -f openshift/config/csi/vault-provider.yaml
oc apply -f openshift/config/csi/secret-provider-class.yaml

echo "Waiting for Vault CSI provider to be ready..."
sleep 10
oc rollout status daemonset/vault-csi-provider -n csi-driver --timeout=120s || true

echo "Verifying CSI installation..."
oc get pods,daemonset -n csi-driver
oc get SecretProviderClass -n tekton-vault

echo "Secrets Store CSI Driver and Vault Provider installation complete!" 