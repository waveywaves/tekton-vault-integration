#!/bin/bash
set -e

echo "Setting up OpenShift cluster connection..."

# Check if oc is installed
if ! command -v oc &> /dev/null; then
    echo "Error: OpenShift CLI (oc) is not installed. Please install it first."
    exit 1
fi

# Check if we're logged in
if ! oc whoami &> /dev/null; then
    echo "You are not logged into an OpenShift cluster."
    echo "Please log in using one of these methods:"
    echo "1. oc login <cluster_url> -u <username> -p <password>"
    echo "2. oc login --token=<token> --server=<cluster_url>"
    exit 1
fi

# Create project
echo "Creating project..."
oc new-project tekton-vault || true

# Set security context constraints
echo "Setting security context constraints..."
oc adm policy add-scc-to-user anyuid -z default -n tekton-vault

# Print cluster info
echo "Connected to cluster:"
oc cluster-info

echo "OpenShift cluster setup complete!"
echo "You can now run the installation scripts in order:"
echo "1. ./01-install-openshift-pipelines.sh"
echo "2. ./02-install-vault.sh"
echo "3. ./03-install-csi-provider.sh"
echo "4. ./04-configure-vault.sh"
echo "5. ./05-setup-pipeline.sh" 