#!/bin/bash
set -e

# lets get ourselves to the right place first
cd "$(dirname "$0")"

echo "Starting complete setup process..."

# time to run all our scripts in order - it's like a well-choreographed dance
./00-setup-kind-cluster.sh
./01-install-tekton-pipelines.sh
./02-install-vault.sh
./03-install-csi-provider.sh
./04-configure-vault.sh
./05-setup-pipeline.sh

# woohoo! if we made it here, everything went according to plan
echo "Complete setup process finished successfully!" 