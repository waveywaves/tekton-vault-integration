#!/bin/bash
set -e

echo "Installing Secrets Store CSI Driver and Vault Provider..."

oc create namespace csi-driver || true
oc create namespace csi || true

oc apply -f ../config/csi/rbac.yaml
oc apply -f ../config/csi/scc.yaml
oc adm policy add-scc-to-user vault-csi-provider-scc system:serviceaccount:csi:secrets-store-csi-driver

helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo update

helm upgrade --install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace csi-driver \
  -f ../config/csi/values.yaml

echo "Waiting for CSI driver to be ready..."
oc rollout status daemonset/csi-secrets-store-secrets-store-csi-driver -n csi-driver --timeout=120s

oc apply -f ../config/csi/vault-provider.yaml
oc apply -f ../config/csi/secret-provider-class.yaml

echo "Waiting for Vault CSI provider to be ready..."
sleep 10
oc rollout status daemonset/vault-csi-provider -n csi-driver --timeout=120s || true

echo "Verifying CSI installation..."
oc get pods,daemonset -n csi-driver
oc get SecretProviderClass -n tekton-vault

echo "Secrets Store CSI Driver and Vault Provider installation complete!" 