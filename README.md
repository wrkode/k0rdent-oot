# k0rdent/kcm (out-of-tree)

This repository contains out-of-tree Helm chart(s) for [k0rdent/kcm](https://docs.k0rdent.io/v0.2.0/quickstarts/quickstart-1-mgmt-node-and-cluster/#install-k0rdent).

## Version

Based on chart version: 0.2.0

## Install `k0rdent/kcm` into Kubernetes cluster

> Note: for the `KinD` based cluster use [setup script](/scripts/kind.sh), to use image registry proxy `export REGISTRY_PROXY=image.proxy.net`

```bash
helm install kcm oci://ghcr.io/k0rdent/kcm/charts/kcm --version 0.2.0 -n kcm-system --create-namespace \
	--set controller.enableTelemetry=false
```

## CAPI specific guides

- [KubeVirt](/KUBEVIRT.md)
