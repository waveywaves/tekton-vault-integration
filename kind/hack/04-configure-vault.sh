#!/bin/bash
set -e

echo "Configuring Vault..."

# Create temporary directory for files
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "${TEMP_DIR}"' EXIT

# Start port-forwarding in the background
kubectl port-forward -n vault vault-0 8200:8200 &
PORTFORWARD_PID=$!

# Wait for port-forward to be ready
sleep 5

# Set Vault address and token
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

# Create service account and role binding for Vault authentication
kubectl create serviceaccount vault-auth || true
kubectl create clusterrolebinding vault-auth-binding \
    --clusterrole=system:auth-delegator \
    --serviceaccount=default:vault-auth || true

# Create pipeline service account
kubectl apply -f ../../kind/config/pipeline/01-pipeline-sa.yaml

# Configure Kubernetes authentication
KUBE_HOST="https://kubernetes.default.svc.cluster.local:443"
VAULT_SA_TOKEN=$(kubectl create token vault-auth)

# Get Kubernetes CA certificate
kubectl config view --raw --minify --flatten \
    -o jsonpath='{.clusters[].cluster.certificate-authority-data}' \
    | base64 -d > "${TEMP_DIR}/ca.crt"

# Enable and configure Kubernetes auth method
vault auth enable kubernetes || true
vault write auth/kubernetes/config \
    token_reviewer_jwt="$VAULT_SA_TOKEN" \
    kubernetes_host="$KUBE_HOST" \
    kubernetes_ca_cert=@"${TEMP_DIR}/ca.crt" \
    disable_local_ca_jwt="true"

# Enable KV secrets engine and create secret
vault secrets enable -path=secret kv-v2 || true
vault kv put secret/my-secret \
    username="demo-user" \
    password="demo-pass"

# Create policy for accessing secret
echo 'path "secret/data/my-secret" { capabilities = ["read"] }' | vault policy write my-policy -

# Create Kubernetes authentication role
vault write auth/kubernetes/role/my-role \
    bound_service_account_names=pipeline-sa \
    bound_service_account_namespaces=default \
    policies=my-policy \
    ttl=1h

# Test authentication
echo "Testing Vault authentication..."
TOKEN=$(kubectl create token pipeline-sa)
vault write auth/kubernetes/login role=my-role jwt=$TOKEN

# Clean up
kill $PORTFORWARD_PID || true

echo "Vault configuration complete!" 