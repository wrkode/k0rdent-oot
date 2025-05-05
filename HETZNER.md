# k0rdent/kcm (out-of-tree), Hetzner Provider

## Install `k0rdent/kcm` into Kubernetes cluster

```bash
helm install kcm oci://ghcr.io/k0rdent/kcm/charts/kcm --version 0.3.0 -n kcm-system --create-namespace \
  --set controller.enableTelemetry=false \
  --set velero.enabled=false
```

## Wait for `Management` object readiness

```bash
kubectl wait --for=condition=Ready=True management/kcm --timeout=300s
```

## Install `Hetzner` chart

> Note: can also create manifests directly, see `hetzner-pp` Helm Chart

```bash
helm install hetzner-pp oci://ghcr.io/k0rdent-oot/oot/charts/hetzner-pp -n kcm-system --take-ownership
```

## Update `Management` object to enable `Hetzner` provider

```bash
kubectl patch mgmt kcm \
  --type='json' \
  -p='[
    {
      "op": "add",
      "path": "/spec/providers/-",
      "value": {
        "name": "cluster-api-provider-hetzner",
        "template": "cluster-api-provider-hetzner-0-3-0",
      }
    }
  ]'
```

## Wait for `Management` object readiness

```bash
kubectl wait --for=condition=Ready=True management/kcm --timeout=300s
```

## Create a `Hetzner` child cluster

```bash
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: hetzner-config
  namespace: kcm-system
  labels:
    k0rdent.mirantis.com/component: "kcm"
stringData:
  hcloud: ***TOKEN***
---
apiVersion: k0rdent.mirantis.com/v1alpha1
kind: Credential
metadata:
  name: hetzner-cluster-identity-cred
  namespace: kcm-system
spec:
  description: Hetzner credentials
  identityRef:
    apiVersion: v1
    kind: Secret
    name: hetzner-config
    namespace: kcm-system
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: hetzner-config-resource-template
  namespace: kcm-system
  labels:
    k0rdent.mirantis.com/component: "kcm"
  annotations:
    projectsveltos.io/template: "true"
EOF

kubectl apply -f - <<EOF
---
apiVersion: k0rdent.mirantis.com/v1alpha1
kind: ClusterDeployment
metadata:
  name: hetzner-demo
  namespace: kcm-system
spec:
  template: hetzner-standalone-cp-0-3-0
  credential: hetzner-cluster-identity-cred
  config:
    region: fsn1
    sshkey:
      name: id_ed25519
    controlPlane:
      type: cpx31
    worker:
      type: cpx21
EOF
```

## Steps to debug child `Hetzner` cluster deployment:

#### Describe cluster status.

```bash
clusterctl describe cluster hetzner-demo -n kcm-system
```

#### Get `ClusterDeployment` objects.

```bash
kubectl get cld -A
```

#### Get `Machine` object.

```bash
kubectl get machine -A
```

#### Get child cluster `kubeconfig` where `hetzner-demo` is the cluster name.

```bash
clusterctl get kubeconfig hetzner-demo -n kcm-system > hetzner-demo.kubeconfig
```

#### Test `kubeconfig`.

```bash
kubectl --kubeconfig=./hetzner-demo.kubeconfig get nodes -o wide
```
