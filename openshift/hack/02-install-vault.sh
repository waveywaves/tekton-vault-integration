#!/bin/bash
set -e

echo "Installing Vault..."

# Add HashiCorp Helm repository
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Create namespace if it doesn't exist
oc create namespace vault || true

# Install Vault with OpenShift-specific values
cat <<EOF | helm install vault hashicorp/vault --namespace vault -f -
global:
  openshift: true
server:
  dev:
    enabled: true
  standalone:
    config: |
      ui = true
      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }
      storage "file" {
        path = "/vault/data"
      }
  service:
    annotations:
      service.beta.openshift.io/serving-cert-secret-name: vault-server-tls
  extraEnvironmentVars:
    VAULT_ADDR: http://127.0.0.1:8200
    VAULT_TOKEN: root
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000700000
EOF

# Wait for Vault pod to be ready
echo "Waiting for Vault pod to be ready..."
oc wait --for=condition=ready pod -l app.kubernetes.io/name=vault --namespace vault --timeout=120s

# Verify installation
echo "Verifying Vault installation..."
oc get pods -n vault

echo "Vault installation complete!" 