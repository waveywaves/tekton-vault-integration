#!/bin/bash
set -e

# Change to the script directory
cd "$(dirname "$0")"

echo "Starting complete setup process..."

# Run all scripts in sequence
./00-setup-kind-cluster.sh
./01-install-tekton-pipelines.sh
./02-install-vault.sh
./03-install-csi-provider.sh
./04-configure-vault.sh
./05-setup-pipeline.sh

echo "Complete setup process finished successfully!" 