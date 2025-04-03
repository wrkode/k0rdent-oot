# k0rdent/kcm (out-of-tree)

## Debug charts

### Pull

```bash
helm pull oci://ghcr.io/k0rdent/kcm/charts/kcm --version 0.2.0 --untar --untardir ./TEMP/.
helm pull oci://ghcr.io/k0rdent/kcm/charts/kcm-templates --version 0.2.0 --untar --untardir ./TEMP/.
helm pull oci://ghcr.io/k0rdent/kcm/charts/cluster-api-provider-openstack --version 0.2.0 --untar --untardir ./TEMP/.
helm pull oci://ghcr.io/k0rdent/kcm/charts/openstack-standalone-cp --version 0.2.0 --untar --untardir ./TEMP/.

helm pull oci://ghcr.io/s3rj1k/k0rdent-kcm-oot/charts/cluster-api-provider-kubevirt --version 0.2.0 --untar --untardir ./TEMP/.
helm pull oci://ghcr.io/s3rj1k/k0rdent-kcm-oot/charts/kubevirt-standalone-cp --version 0.2.0 --untar --untardir ./TEMP/.
```

### Render

```bash
helm template kcm oci://ghcr.io/k0rdent/kcm/charts/kcm --version 0.2.0 -n kcm-system --output-dir ./TEMP/.
helm template kcm oci://ghcr.io/k0rdent/kcm/charts/kcm-templates --version 0.2.0 -n kcm-system --output-dir ./TEMP/.
helm template kcm oci://ghcr.io/k0rdent/kcm/charts/cluster-api-provider-openstack --version 0.2.0 -n kcm-system --output-dir ./TEMP/.
helm template kcm oci://ghcr.io/k0rdent/kcm/charts/openstack-standalone-cp --version 0.2.0 -n kcm-system --output-dir ./TEMP/.

helm template kcm oci://ghcr.io/s3rj1k/k0rdent-kcm-oot/charts/cluster-api-provider-kubevirt --version 0.2.0 -n kcm-system --output-dir ./TEMP/.
helm template kcm oci://ghcr.io/s3rj1k/k0rdent-kcm-oot/charts/kubevirt-standalone-cp --version 0.2.0 -n kcm-system --output-dir ./TEMP/.
```
