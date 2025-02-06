#!/bin/bash
set -e

echo "Setting up kind cluster..."

# figure out where we are and where we need to be
SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "Deleting existing kind cluster (if any)..."
kind delete cluster || true

mkdir -p /tmp/kind-mount

echo "Creating new kind cluster..."
kind create cluster --config "${PROJECT_ROOT}/kind/config/kind/config.yaml"

echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=ready node/kind-control-plane --timeout=120s

# double check our connection details
echo "Updating kubeconfig..."
kubectl cluster-info

echo "Kind cluster setup complete!"
echo "You can now run the installation scripts in order:"
echo "1. ./01-install-tekton-pipelines.sh"
echo "2. ./02-install-vault.sh"
echo "3. ./03-install-csi-provider.sh"
echo "4. ./04-configure-vault.sh"
echo "5. ./05-setup-pipeline.sh" 