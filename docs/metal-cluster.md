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
