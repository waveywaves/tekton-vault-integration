# Tekton Pipelines with Vault

This is a simple example of how to use Tekton Pipelines with Vault.

## Prerequisites

- Kubernetes
- Tekton Pipelines
- Vault
- Secrets Store CSI Driver

## Setup

1. Install Tekton Pipelines
2. Install Vault
3. Install Secrets Store CSI Driver

### Installing Vault on Kind

To install Vault on your Kind cluster:

1. Add the HashiCorp Helm repository:
```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
```

2. Create a namespace for Vault:
```bash
kubectl create namespace vault
```

3. Install Vault using Helm:
```bash
helm install vault hashicorp/vault \
  --namespace vault \
  --set "server.dev.enabled=true" \
  --set "server.dev.devRootToken=root"
```

4. Verify the installation:
```bash
kubectl get pods -n vault
```

The Vault pod should be running. You can access Vault using the root token "root" in dev mode. Note that this is a development setup and should not be used in production.

### Installing Secrets Store CSI Driver on Kind

To install the Secrets Store CSI Driver on your Kind cluster:

1. Add the Secrets Store CSI Driver Helm repository:
```bash
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo update
```

2. Create a namespace for the CSI driver:
```bash
kubectl create namespace csi-driver
```

3. Install the Secrets Store CSI Driver using Helm:
```bash
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace csi-driver \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true
```

4. Install the Vault CSI Provider:
```bash
helm install vault-csi-provider hashicorp/vault-secrets-operator \
  --namespace csi-driver \
  --set "defaultVaultConnection.address=http://vault.vault.svc.cluster.local:8200" \
  --set "defaultVaultConnection.enabled=true"
```

5. Verify the installation:
```bash
kubectl get pods -n csi-driver
```

You should see the CSI driver and Vault provider pods running. The CSI driver is now ready to mount Vault secrets into your pods.
