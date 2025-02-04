#!/bin/bash
set -e

echo "Installing Secrets Store CSI Driver and Vault Provider..."

# Create namespaces
oc create namespace csi-driver || true
oc create namespace csi || true

# Install the Secrets Store CSI Driver Operator
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: secrets-store-csi-driver-operator
  namespace: openshift-operators
spec:
  channel: preview
  name: secrets-store-csi-driver-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

# Wait for the operator to be ready
echo "Waiting for Secrets Store CSI Driver operator to be ready..."
while ! oc get deployment secrets-store-csi-driver-operator -n openshift-operators &> /dev/null; do
    echo "Waiting for operator deployment..."
    sleep 5
done

# Wait for the deployment to be ready
oc wait --for=condition=available deployment/secrets-store-csi-driver-operator -n openshift-operators --timeout=300s

# Wait for CRDs to be installed
echo "Waiting for CRDs to be installed..."
while ! oc get crd secretproviderclasses.secrets-store.csi.x-k8s.io &> /dev/null; do
    echo "Waiting for SecretProviderClass CRD..."
    sleep 5
done

# Create the SecretProviderClass for Vault
cat <<EOF | oc apply -f -
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: vault-provider
  namespace: tekton-vault
spec:
  provider: vault
  parameters:
    vaultAddress: "http://vault.vault:8200"
    vaultSkipTLSVerify: "true"
    roleName: "my-role"
    objects: |
      - objectName: "demo-secret"
        secretPath: "secret/data/my-secret"
        secretKey: "username"
      - objectName: "demo-secret-pass"
        secretPath: "secret/data/my-secret"
        secretKey: "password"
EOF

# Wait for the CSI driver DaemonSet to be ready
echo "Waiting for CSI driver DaemonSet to be ready..."
while ! oc get daemonset secrets-store-csi-driver-node -n openshift-operators &> /dev/null; do
    echo "Waiting for CSI driver DaemonSet..."
    sleep 5
done

# Wait for the DaemonSet to be ready
oc rollout status daemonset/secrets-store-csi-driver-node -n openshift-operators --timeout=300s

# Verify installation
echo "Verifying CSI installation..."
oc get pods -n openshift-operators | grep secrets-store
oc get SecretProviderClass -n tekton-vault

# Create RBAC for Vault CSI Provider
echo "Creating RBAC for Vault CSI Provider..."
cat <<EOF | oc apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secrets-store-csi-driver
  namespace: csi
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secretproviderclasses-role
rules:
- apiGroups: ["secrets-store.csi.x-k8s.io"]
  resources: ["secretproviderclasses"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: secretproviderclasses-rolebinding
subjects:
- kind: ServiceAccount
  name: secrets-store-csi-driver
  namespace: csi
roleRef:
  kind: ClusterRole
  name: secretproviderclasses-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secretprovidersyncing-role
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: secretprovidersyncing-rolebinding
subjects:
- kind: ServiceAccount
  name: secrets-store-csi-driver
  namespace: csi
roleRef:
  kind: ClusterRole
  name: secretprovidersyncing-role
  apiGroup: rbac.authorization.k8s.io
EOF

# Wait for service account to be ready
echo "Waiting for service account to be ready..."
while ! oc get serviceaccount secrets-store-csi-driver -n csi &> /dev/null; do
    echo "Waiting for service account..."
    sleep 5
done

# Create custom SecurityContextConstraints
echo "Creating custom SecurityContextConstraints..."
cat <<EOF | oc apply -f -
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
  name: vault-csi-provider-scc
allowHostDirVolumePlugin: true
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegeEscalation: true
allowPrivilegedContainer: false
allowedCapabilities: null
defaultAddCapabilities: null
fsGroup:
  type: RunAsAny
groups: []
priority: null
readOnlyRootFilesystem: false
requiredDropCapabilities:
- KILL
- MKNOD
- SETUID
- SETGID
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: RunAsAny
supplementalGroups:
  type: RunAsAny
users:
- system:serviceaccount:csi:secrets-store-csi-driver
volumes:
- hostPath
- configMap
- downwardAPI
- emptyDir
- persistentVolumeClaim
- projected
- secret
EOF

# Add security context constraints
echo "Adding security context constraints..."
oc adm policy add-scc-to-user vault-csi-provider-scc system:serviceaccount:csi:secrets-store-csi-driver

# Deploy the Vault CSI Provider
echo "Deploying Vault CSI Provider..."
cat <<EOF | oc apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: vault-csi-provider
  namespace: csi
  labels:
    app: vault-csi-provider
spec:
  selector:
    matchLabels:
      app: vault-csi-provider
  template:
    metadata:
      labels:
        app: vault-csi-provider
    spec:
      serviceAccountName: secrets-store-csi-driver
      containers:
        - name: provider
          image: hashicorp/vault-csi-provider:1.4.0
          imagePullPolicy: IfNotPresent
          args:
            - --endpoint=/provider/vault.sock
            - --debug=false
          securityContext:
            privileged: true
            runAsUser: 0
          resources:
            requests:
              cpu: 50m
              memory: 100Mi
            limits:
              cpu: 50m
              memory: 100Mi
          volumeMounts:
            - name: providervol
              mountPath: "/provider"
      volumes:
        - name: providervol
          hostPath:
            path: "/etc/kubernetes/secrets-store-csi-providers"
            type: DirectoryOrCreate
EOF

echo "Secrets Store CSI Driver and Vault Provider installation complete!" 