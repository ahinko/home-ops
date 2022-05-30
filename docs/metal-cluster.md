# ⛵ Kubernetes

## Getting started
There are a few things we need to do to get the metal cluster up and running.

First, take a look at the [configuration files for the cluster](../kubernetes/management/sidero-system) and modify them to match your needs. If you need any help I would suggest to first take a look at the [Sidero](https://sidero.dev/docs) and [Talos](https://talos.dev/docs) documentations and try and find the answers there.

Next step is to update your bios settings on your metal nodes to make sure they network boot and of course they also need to be on the same VLAN as the Sidero management cluster.

If everything is set up correctly the nodes should automatically network boot from the Sidero management cluster and they should be accepted and allocated and the cluster should be provisioned.

Finally run:

```shell
$ task metal:bootstrap
```

This script will for example get the `kubeconfig` and do some final setup to create the metal cluster.

## Upgrades
Renovate will update all needed files when there is either a Talos update or Kubernetes update available. Renovate will also keep track of which Kubernetes versions the currenty installed Talos version supports. When a pull requests is created we need to merge the pull request.

Sidero does currently NOT support rolling updates but lets hope it gets implemented soon. Until then we need to reset one node at the time and wait for it to come back before resetting the next. It's the same process for both Talos and Kubernetes updates.

**ALWAYS START WITH WORKER NODES**

```
$ talosctl reset --nodes <IP>
```
