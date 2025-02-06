# Tekton Vault Integration for OpenShift

Example of integrating OpenShift Pipelines with HashiCorp Vault using the Secrets Store CSI Driver.

## Prerequisites

- Access to an OpenShift cluster
- `oc` CLI tool
- `helm` CLI tool
- `vault` CLI tool
- Cluster admin privileges

## Quick Start

```bash
# Log in to your OpenShift cluster
oc login --token=<your_token> --server=<cluster_url>

# Run complete setup
./openshift/hack/setup-all.sh
```

This will:
1. Set up the required project and permissions
2. Install OpenShift Pipelines Operator
3. Install Vault in dev mode
4. Install Secrets Store CSI Driver
5. Configure Vault with OpenShift authentication
6. Run a test pipeline that reads secrets from Vault

## Manual Setup

Individual setup scripts are available in the `openshift/hack` directory:

```bash
./openshift/hack/00-setup-cluster.sh
./openshift/hack/01-install-openshift-pipelines.sh
./openshift/hack/02-install-vault.sh
./openshift/hack/03-install-csi-provider.sh
./openshift/hack/04-configure-vault.sh
./openshift/hack/05-setup-pipeline.sh
```

## Configuration

All configuration files are in the `openshift/config` directory:
- Pipeline manifests: `openshift/config/pipeline/*.yaml`

## Notes

- OpenShift Pipelines is based on Tekton but is installed via the OpenShift Pipelines Operator
- The service account and security context configurations are adjusted for OpenShift's security requirements
- The CSI driver installation is handled differently in OpenShift compared to kind/kubernetes

## Cleanup

```bash
# Delete the project and all resources
oc delete project tekton-vault

# Remove cluster-wide resources
oc delete clusterrolebinding vault-auth-binding
``` 