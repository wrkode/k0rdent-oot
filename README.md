# k0rdent/kcm (out-of-tree)

This repository contains out-of-tree Helm chart(s) for [k0rdent/kcm](https://docs.k0rdent.io/v0.2.0/quickstarts/quickstart-1-mgmt-node-and-cluster/#install-k0rdent).

## Pull

```bash
helm pull oci://ghcr.io/k0rdent/kcm/charts/kcm --version 0.2.0 --untar --untardir ./TEMP/.
helm pull oci://ghcr.io/k0rdent/kcm/charts/kcm-templates --version 0.2.0 --untar --untardir ./TEMP/.
helm pull oci://ghcr.io/k0rdent/kcm/charts/cluster-api-provider-openstack --version 0.2.0 --untar --untardir ./TEMP/.
helm pull oci://ghcr.io/k0rdent/kcm/charts/openstack-standalone-cp --version 0.2.0 --untar --untardir ./TEMP/.
```

## Render

```bash
helm template kcm oci://ghcr.io/k0rdent/kcm/charts/kcm --version 0.2.0 -n kcm-system --output-dir ./TEMP/.
helm template kcm oci://ghcr.io/k0rdent/kcm/charts/kcm-templates --version 0.2.0 -n kcm-system --output-dir ./TEMP/.
helm template kcm oci://ghcr.io/k0rdent/kcm/charts/cluster-api-provider-openstack --version 0.2.0 -n kcm-system --output-dir ./TEMP/.
helm template kcm oci://ghcr.io/k0rdent/kcm/charts/openstack-standalone-cp --version 0.2.0 -n kcm-system --output-dir ./TEMP/.
```

## Version

Based on chart version: 0.2.0
