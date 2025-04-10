# k0rdent/kcm (out-of-tree)

# KubeVirt

## Add `KubeVirt` provider

```bash
cat << 'EOF' | jq -Rs '{data:{"kubevirt.yml":.}}' | kubectl patch configmap providers -n kcm-system --type=merge --patch-file /dev/stdin
# SPDX-License-Identifier: Apache-2.0
name: kubevirt
clusterGVKs:
  - group: infrastructure.cluster.x-k8s.io
    version: v1alpha1
    kind: KubevirtCluster
clusterIdentityKinds:
  - Secret
EOF
```

## Restart `KCM` manager controller

```bash
kubectl -n kcm-system rollout restart deployment/kcm-controller-manager
```

## Create templates for `KubeVirt` provider charts

```bash
kubectl apply -f - <<EOF
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: oot-repo
  namespace: kcm-system
  labels:
    k0rdent.mirantis.com/managed: "true"
spec:
  type: oci
  url: 'oci://ghcr.io/s3rj1k/k0rdent-kcm-oot/charts'
  interval: 10m0s
---
apiVersion: k0rdent.mirantis.com/v1alpha1
kind: ProviderTemplate
metadata:
  name: cluster-api-provider-kubevirt-0-2-0
  annotations:
    helm.sh/resource-policy: keep
spec:
  helm:
    chartSpec:
      chart: cluster-api-provider-kubevirt
      version: 0.2.0
      interval: 10m0s
      sourceRef:
        kind: HelmRepository
        name: oot-repo
---
apiVersion: k0rdent.mirantis.com/v1alpha1
kind: ClusterTemplate
metadata:
  name: kubevirt-standalone-cp-0-2-0
  namespace: kcm-system
  annotations:
    helm.sh/resource-policy: keep
spec:
  helm:
    chartSpec:
      chart: kubevirt-standalone-cp
      version: 0.2.0
      interval: 10m0s
      sourceRef:
        kind: HelmRepository
        name: oot-repo
EOF
```

## Add the `KubeVirt` chart into the `Management` object

```bash
until kubectl patch management kcm --type=json -p='[
  {"op": "add", "path": "/spec/providers/-", "value": {"name": "cluster-api-provider-kubevirt", "template": "cluster-api-provider-kubevirt-0-2-0"}}
]'; do
  sleep 5
done
```

## Wait for `Management` object readiness

```bash
kubectl wait --for=condition=Ready=True management/kcm --timeout=300s
```

## Install `KubeVirt` charts

```bash
export KUBEVIRT_VERSION=$(curl -s "https://api.github.com/repos/kubevirt/kubevirt/releases/latest" | jq -r ".tag_name")

until kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml" ; do
  sleep 5
done

until kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml" ; do
  sleep 5
done

until kubectl -n kubevirt patch kubevirt kubevirt --type=merge --patch '{"spec":{"configuration":{"developerConfiguration":{"useEmulation":true}}}}' ; do
  sleep 5
done

kubectl wait -n kubevirt kv kubevirt --for=condition=Available --timeout=10m
```

## Install `KubeVirt` CLI
```bash
KUBEVIRT_VERSION=$(kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.observedKubeVirtVersion}")
ARCH=$(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/amd64/')
sudo curl -L -o /usr/local/bin/virtctl https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/virtctl-${KUBEVIRT_VERSION}-${ARCH}
sudo chmod +x /usr/local/bin/virtctl
```

## Create a `KubeVirt` child cluster

```bash
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: kubevirt-config
  namespace: kcm-system
  labels:
    k0rdent.mirantis.com/component: "kcm"
---
apiVersion: k0rdent.mirantis.com/v1alpha1
kind: Credential
metadata:
  name: kubevirt-cluster-identity-cred
  namespace: kcm-system
spec:
  description: KubeVirt credentials
  identityRef:
    apiVersion: v1
    kind: Secret
    name: kubevirt-config
    namespace: kcm-system
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: kubevirt-config-resource-template
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
  name: kubevirt-demo
  namespace: kcm-system
spec:
  template: kubevirt-standalone-cp-0-2-0
  credential: kubevirt-cluster-identity-cred
  config:
    controlPlaneNumber: 1
    workersNumber: 1
    controlPlane:
      preStartCommands:
        - passwd -u root
        - echo "root:root" | chpasswd
    worker:
      preStartCommands:
        - passwd -u root
        - echo "root:root" | chpasswd
EOF
```

## Steps to debug child `KubeVirt` cluster deployment:

- `clusterctl describe cluster kubevirt-demo`
- `kubectl get cld -A`
- `kubectl get cluster,machine`
- `kubectl get K0sControlPlane,KubevirtCluster`
- `kubectl get vm,vmi`

> Note: to get into the Machine console use `virtctl console kubevirt-demo-cp-0` where `kubevirt-demo-cp-0`
  is `Machine` name, to set console size use `stty rows 40 cols 1000`.

> Note: to get child cluster kubeconfig `clusterctl get kubeconfig kubevirt-demo > kubevirt-demo.kubeconfig`
  where `kubevirt-demo` is the cluster name, test kubeconfig with `kubectl --kubeconfig=./kubevirt-demo.kubeconfig get nodes -o wide`
