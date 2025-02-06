#!/bin/bash
set -e

# vault in dev mode with kubernetes root token
echo "Configuring Vault..."

# temporary directory for files
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "${TEMP_DIR}"' EXIT

# this port-forward thing is kinda sketchy - could fail silently
oc port-forward -n vault vault-0 8200:8200 &
PORTFORWARD_PID=$!

# using sleep is bad practice - should check if port-forward is actually ready
sleep 5

# dont hardcode these in prod - especially not the root token!
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

# service account and role binding for vault authentication
oc create serviceaccount vault-auth -n tekton-vault || true
oc create clusterrolebinding vault-auth-binding \
    --clusterrole=system:auth-delegator \
    --serviceaccount=tekton-vault:vault-auth || true

oc apply -f openshift/config/pipeline/01-pipeline-sa.yaml

KUBE_HOST="https://kubernetes.default.svc.cluster.local:443"
VAULT_SA_TOKEN=$(oc create token vault-auth -n tekton-vault)

oc get configmap kube-root-ca.crt -n tekton-vault -o jsonpath='{.data.ca\.crt}' > "${TEMP_DIR}/ca.crt"

# enabling auth without checking if its already configured right
vault auth enable kubernetes || true
vault write auth/kubernetes/config \
    token_reviewer_jwt="$VAULT_SA_TOKEN" \
    kubernetes_host="$KUBE_HOST" \
    kubernetes_ca_cert=@"${TEMP_DIR}/ca.crt" \
    disable_local_ca_jwt="true"

# using kv-v2 but not setting any max versions or cleanup policy
vault secrets enable -path=secret kv-v2 || true
# demo credentials in plain text - bad practice
vault kv put secret/my-secret \
    username="demo-user" \
    password="demo-pass"

# policy could be more restrictive - currently allows read on all versions
echo 'path "secret/data/my-secret" { capabilities = ["read"] }' | vault policy write my-policy -

# 1 hour ttl might be too long/short depending on your needs
vault write auth/kubernetes/role/my-role \
    bound_service_account_names=pipeline-sa \
    bound_service_account_namespaces=tekton-vault \
    policies=my-policy \
    ttl=1h

echo "Testing Vault authentication..."
TOKEN=$(oc create token pipeline-sa -n tekton-vault)
vault write auth/kubernetes/login role=my-role jwt=$TOKEN

kill $PORTFORWARD_PID || true

echo "Vault configuration complete!" 