# Snippets & notes

Snippets and notes about how to fix problems where a [task](../.taskfiles/) was to complex to set up.

## Postgres restore backup

Look at these links on how to spin up a new cluster from backups:

- [bootstrap-from-a-backup-recovery](https://cloudnative-pg.io/documentation/1.16/bootstrap/#bootstrap-from-a-backup-recovery)
- [backup_recovery](https://cloudnative-pg.io/documentation/1.16/backup_recovery/)

Manual backups:

```shell
pg_dump -h 192.168.20.204 -U postgres -W -d nextcloud > ./nextcloud_backup.sql
psql -h 192.168.20.204 -U postgres -W -d nextcloud < ./nextcloud_backup.sql
```

## Reset node

I have this recurring issue where one of the master nodes (a RPi 4) ends up in a weird state and its "NotReady". The only fix I have found is to reset the node:

```shell
talosctl etcd remove-member <node> -n <ip>
talosctl reset --system-labels-to-wipe=STATE,EPHEMERAL --reboot --graceful=false -n <ip>
talosctl apply-config -n <ip> -f clusterconfig/metal-<node>.yaml --insecure
```

## Reset Rook Ceph cluster

I ran in to an issue where I had to reset the Rook-Ceph cluster due to restructuring the repo. I should have been more careful but it was also a learning experience. To fully reset the cluster I had to go through the following steps.:

* Suspend Flux reconciliations: `flux suspend reconciliation kustomization rook-ceph-cluster` and `flux suspend reconciliation kustomization rook-ceph-operator`
* Delete the file system: `kubectl delete cephfilesystem -n rook-ceph myfs`
* Might need to handle finalizers in some caes: `kubectl patch cephfilesystem -n rook-ceph myfs -p '{"metadata":{"finalizers":[]}}' --type=merge`
* Delete the cluster: `kubectl delete cephclusters.ceph.rook.io -n rook-ceph rook-ceph`
* Handle cluster finalizers: `kubectl patch cephclusters.ceph.rook.io -n rook-ceph rook-ceph -p '{"metadata":{"finalizers":[]}}' --type=merge`
* Delete all resources: `kubectl delete all -n rook-ceph --force --grace-period=0`
* Delete all CRDs that starts with ceph*
* Wipe disks: `kubectl apply -f kubernetes/tools/rook/wipe.yaml`
* Reset nodes and reboot: `talosctl reset --system-labels-to-wipe=STATE,EPHEMERAL --reboot --graceful=true -n <IP>`
  * Apply config again: `talosctl apply-config -n <IP> -f infrastructure/talos/clusterconfig/<CONFIG FILE>.yaml --insecure`

## /var is filling up

I had an issue where the /var directory on some of my nodes was filling up. Seems to have been containerd cache that didn't clear correctly. I fixed this by reseting the node and applying the Talos config again:

* Reset nodes and reboot: `talosctl reset --system-labels-to-wipe=STATE,EPHEMERAL --reboot --graceful=true -n <IP>`
* Apply config again: `talosctl apply-config -n <IP> -f infrastructure/talos/clusterconfig/<CONFIG FILE>.yaml --insecure`
