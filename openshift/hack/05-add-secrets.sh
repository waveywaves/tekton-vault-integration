 #!/bin/bash
set -e

echo "Configuring Vault secrets and policies..."

VAULT_URL="https://$(oc get route vault -n vault -o jsonpath='{.spec.host}')"
export VAULT_ADDR="${VAULT_URL}"
export VAULT_TOKEN='root'
export VAULT_SKIP_VERIFY=true  # since we're using self-signed certs

echo "Creating demo secret..."
vault kv put secret/my-secret \
    username="demo-user" \
    password="demo-pass"

echo "Creating access policy..."
echo 'path "secret/data/my-secret" { capabilities = ["read"] }' | vault policy write my-policy -

echo "Configuring Kubernetes role..."
vault write auth/kubernetes/role/my-role \
    bound_service_account_names=pipeline-sa \
    bound_service_account_namespaces=tekton-vault \
    policies=my-policy \
    ttl=1h

echo "Testing Vault authentication..."
TOKEN=$(oc create token pipeline-sa -n tekton-vault)
vault write auth/kubernetes/login role=my-role jwt=$TOKEN

echo "Secret and policy configuration complete!"
echo "Created secret: secret/my-secret"
echo "Created policy: my-policy"
echo "Created role: my-role"