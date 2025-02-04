# Tekton Vault Integration

Example of integrating Tekton Pipelines with HashiCorp Vault using the Secrets Store CSI Driver.

## Prerequisites

- Kubernetes cluster (tested with kind)
- kubectl
- helm
- vault CLI

## Quick Start

```bash
# Run complete setup
./kind/hack/setup-all.sh
```

This will:
1. Create a kind cluster
2. Install Tekton Pipelines
3. Install Vault in dev mode
4. Install Secrets Store CSI Driver
5. Configure Vault with Kubernetes authentication
6. Run a test pipeline that reads secrets from Vault

## Manual Setup

Individual setup scripts are available in the `kind/hack` directory:

```bash
./kind/hack/00-setup-kind-cluster.sh
./kind/hack/01-install-tekton-pipelines.sh
./kind/hack/02-install-vault.sh
./kind/hack/03-install-csi-provider.sh
./kind/hack/04-configure-vault.sh
./kind/hack/05-setup-pipeline.sh
```

## Configuration

All configuration files are in the `kind/config` directory:
- Kind cluster: `kind/config/kind/config.yaml`
- Pipeline manifests: `kind/config/pipeline/*.yaml`

## Cleanup

```bash
kind delete cluster
```
