#!/bin/bash
set -e

echo "Starting complete setup process..."

# Get the script's directory
SCRIPT_DIR="$(dirname "$0")"

# Run all setup scripts in sequence
"${SCRIPT_DIR}/00-setup-cluster.sh"
"${SCRIPT_DIR}/01-install-openshift-pipelines.sh"
"${SCRIPT_DIR}/02-install-vault.sh"
"${SCRIPT_DIR}/03-install-csi-provider.sh"
"${SCRIPT_DIR}/04-configure-vault.sh"
"${SCRIPT_DIR}/05-setup-pipeline.sh"

echo "Complete setup process finished successfully!" 