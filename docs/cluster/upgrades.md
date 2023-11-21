# Upgrade Talos & Kubernetes

Renovate keeps track of both Talos versions as well as Kubernetes versions. If a new version is released Renovate will create a pull request that we then can merge.

Talos does however not always support the latest version of Kubernetes. Therefor there is a [Renovate configuration](../../.github/renovate/allowedVersions.json5) that defines which Kubernetes version is supported.
Renovate will not create a pull request for an unsupported Kubernetes version.

There is a [Github action](../../.github/workflows/scan-supported-k8s-version.yaml) that will automatically create a pull request that updates the allowed version when a new Talos release supports a newer version of Kubernetes.

## Upgrade Talos

Talos does not have a built in way of doing a rolling upgrade of the nodes. So I created a script that does just that. The script also makes sure that `rook/ceph` has the time to recover when a `rook/ceph` node is upgraded (and rebooted).

```shell
task talos:upgrade-nodes
```

## Upgrade Kubernetes

Kubernetes can be upgraded by running:

```shell
task talos:upgrade-k8s
```

This script will first make a snapshot of Etcd that can be used for a disaster recovery if something would go wrong.

After that the script will tell Talos to start upgrading Kubernetes one node at the time.

to keep track of the upgrade progress you can use:

```shell
kubectl get nodes
```
