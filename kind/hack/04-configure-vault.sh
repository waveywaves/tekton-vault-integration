#!/bin/bash
set -e

# yo heads up - this script has some problems:
# 1. we're using dev mode with root token - super insecure, dont do this in prod
# 2. port-forward is flaky - if network hiccups, whole thing breaks
# 3. storing secrets in plain text in the script - big no-no for real secrets
# 4. no ha setup - single vault pod means no redundancy
# 5. using sleep for port-forward - should properly wait for readiness instead
# 6. hardcoded ttl values - might need different ones for different envs

echo "Configuring Vault..."

# make a temp directory that cleans itself up when we're done
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "${TEMP_DIR}"' EXIT

# this port-forward thing is kinda sketchy - could fail silently
kubectl port-forward -n vault vault-0 8200:8200 &
PORTFORWARD_PID=$!

# using sleep is bad practice - should check if port-forward is actually ready
sleep 5

# dont hardcode these in prod - especially not the root token!
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

# set up the service account that vault uses to verify k8s tokens
kubectl create serviceaccount vault-auth || true
kubectl create clusterrolebinding vault-auth-binding \
    --clusterrole=system:auth-delegator \
    --serviceaccount=default:vault-auth || true

# create our pipeline's service account - this is what our tasks run as
kubectl apply -f ../../kind/config/pipeline/01-pipeline-sa.yaml

# grab all the kubernetes connection details vault needs
KUBE_HOST="https://kubernetes.default.svc.cluster.local:443"
VAULT_SA_TOKEN=$(kubectl create token vault-auth)

# get the kubernetes ca cert - vault needs this for verification
kubectl config view --raw --minify --flatten \
    -o jsonpath='{.clusters[].cluster.certificate-authority-data}' \
    | base64 -d > "${TEMP_DIR}/ca.crt"

# tell vault how to talk to kubernetes - this is where the magic happens
vault auth enable kubernetes || true
vault write auth/kubernetes/config \
    token_reviewer_jwt="$VAULT_SA_TOKEN" \
    kubernetes_host="$KUBE_HOST" \
    kubernetes_ca_cert=@"${TEMP_DIR}/ca.crt" \
    disable_local_ca_jwt="true"

# set up our secret engine and add test secrets
vault secrets enable -path=secret kv-v2 || true
vault kv put secret/my-secret \
    username="demo-user" \
    password="demo-pass"

# create a policy that lets our pipeline (only) read secrets
echo 'path "secret/data/my-secret" { capabilities = ["read"] }' | vault policy write my-policy -

# set up the role that ties everything together - 
# - service account, namespace, and permissions
vault write auth/kubernetes/role/my-role \
    bound_service_account_names=pipeline-sa \
    bound_service_account_namespaces=default \
    policies=my-policy \
    ttl=1h

# let's make sure everything's working by
# ensuring that we are able to use the same token
# to authenticate with vault as we do with kubernetes
echo "Testing Vault authentication..."
TOKEN=$(kubectl create token pipeline-sa)
vault write auth/kubernetes/login role=my-role jwt=$TOKEN

kill $PORTFORWARD_PID || true

echo "Vault configuration complete!" 