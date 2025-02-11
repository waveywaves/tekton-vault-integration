#!/bin/bash
set -e

echo "Configuring Vault..."

# temporary directory for files
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "${TEMP_DIR}"' EXIT

echo "Creating route for Vault..."
oc create route edge vault --service=vault --port=8200 -n vault || true

echo "Waiting for Vault route to be ready..."
sleep 5

# get url for vault
VAULT_URL="https://$(oc get route vault -n vault -o jsonpath='{.spec.host}')"
export VAULT_ADDR="${VAULT_URL}"
export VAULT_TOKEN='root'
export VAULT_SKIP_VERIFY=true  # Since we're using self-signed certs

# service account and role binding for vault authentication
oc create serviceaccount vault-auth -n tekton-vault || true
oc create clusterrolebinding vault-auth-binding \
    --clusterrole=system:auth-delegator \
    --serviceaccount=tekton-vault:vault-auth || true

oc apply -f openshift/config/pipeline/01-pipeline-sa.yaml

KUBE_HOST="https://kubernetes.default.svc.cluster.local:443"
VAULT_SA_TOKEN=$(oc create token vault-auth -n tekton-vault)

oc get configmap kube-root-ca.crt -n tekton-vault -o jsonpath='{.data.ca\.crt}' > "${TEMP_DIR}/ca.crt"

# Configure Vault
echo "Configuring Vault authentication and secrets..."

# Enable and configure Kubernetes auth
vault auth enable kubernetes || true
vault write auth/kubernetes/config \
    token_reviewer_jwt="$VAULT_SA_TOKEN" \
    kubernetes_host="$KUBE_HOST" \
    kubernetes_ca_cert=@"${TEMP_DIR}/ca.crt" \
    disable_local_ca_jwt="true"

# Enable KV-v2 secrets engine
vault secrets enable -path=secret kv-v2 || true

echo "Vault configuration complete!"
echo "Vault is accessible at: ${VAULT_URL}" 