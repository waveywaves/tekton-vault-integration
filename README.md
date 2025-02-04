# Tekton Vault Integration

This repository demonstrates how to integrate HashiCorp Vault with OpenShift Pipelines (Tekton) using the Secrets Store CSI Driver. It provides a complete setup for securely accessing Vault secrets within Tekton pipelines.

## Prerequisites

- OpenShift cluster with admin access (or Kind cluster for local development)
- `oc` CLI tool installed
- `helm` CLI tool installed
- `tkn` (Tekton) CLI tool installed
- `kind` CLI tool installed (for local development)
- Docker installed and running (for Kind setup)

## Local Development with Kind

For local development and testing, you can use Kind (Kubernetes in Docker) instead of an OpenShift cluster:

1. Create a Kind cluster:
   ```bash
   kind create cluster --name tekton-vault
   ```

2. Install Tekton on Kind:
   ```bash
   kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
   ```

3. Verify Tekton installation:
   ```bash
   kubectl get pods -n tekton-pipelines
   ```

Note: When using Kind, some OpenShift-specific features won't be available. The setup scripts will automatically detect if you're using Kind and adjust accordingly.

## Components Installed

- OpenShift Pipelines Operator (or Tekton on Kind)
- HashiCorp Vault
- Secrets Store CSI Driver
- Vault CSI Provider

## Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/waveywaves/tekton-vault-integration.git
   cd tekton-vault-integration
   ```

2. Run the complete setup:
   ```bash
   ./openshift/hack/setup-all.sh
   ```

   This script will:
   - Set up the OpenShift cluster connection
   - Install OpenShift Pipelines
   - Install and configure HashiCorp Vault
   - Install the Secrets Store CSI Driver
   - Configure Vault authentication
   - Create and run a sample pipeline

## What's Included

- Sample Tekton Task that reads secrets from Vault
- Tekton Pipeline configuration
- Vault configuration for Kubernetes authentication
- SecretProviderClass for CSI Driver configuration
- Service Account and RBAC setup

## Directory Structure

```
.
├── kind/                     # Kind-specific configuration
├── openshift/
│   ├── config/
│   │   ├── pipeline/        # Tekton resources
│   │   └── vault/          # Vault configuration
│   └── hack/               # Setup scripts
```

## Verification

After running the setup, the pipeline will automatically execute and demonstrate reading secrets from Vault. You can verify the setup by checking the pipeline logs:

```bash
tkn pipelinerun logs vault-secret-pipeline-run -n tekton-vault -f
```

## Security Considerations

- The repository uses Kubernetes authentication for Vault
- Service accounts are configured with minimal required permissions
- Secrets are mounted using the CSI driver rather than being exposed as environment variables

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 