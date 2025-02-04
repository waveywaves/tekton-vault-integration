#!/bin/bash
set -e

echo "Setting up kind cluster..."

# Get the script's directory
SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Delete existing cluster if it exists
echo "Deleting existing kind cluster (if any)..."
kind delete cluster || true

# Create mount directory
mkdir -p /tmp/kind-mount

# Create new cluster
echo "Creating new kind cluster..."
kind create cluster --config "${PROJECT_ROOT}/kind/config/kind/config.yaml"

# Wait for cluster to be ready
echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=ready node/kind-control-plane --timeout=120s

# Update kubeconfig
echo "Updating kubeconfig..."
kubectl cluster-info

echo "Kind cluster setup complete!"
echo "You can now run the installation scripts in order:"
echo "1. ./01-install-tekton-pipelines.sh"
echo "2. ./02-install-vault.sh"
echo "3. ./03-install-csi-provider.sh"
echo "4. ./04-configure-vault.sh"
echo "5. ./05-setup-pipeline.sh" 