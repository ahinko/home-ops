# Snippets & notes

Snippets and notes about how to fix problems where a [task](../.taskfiles/) was to complex to set up.

## Postgres restore backup

Look at these links on how to spin up a new cluster from backups:

- [bootstrap-from-a-backup-recovery](https://cloudnative-pg.io/documentation/1.16/bootstrap/#bootstrap-from-a-backup-recovery)
- [backup_recovery](https://cloudnative-pg.io/documentation/1.16/backup_recovery/)

Manual backups:

```shell
pg_dump -h 192.168.20.204 -U nextcloud -W -d nextcloud > ./nextcloud_backup.sql
psql -h 192.168.20.204 -U nextcloud -W -d nextcloud < ./nextcloud_backup.sql
```

## Upgrade Postgres to new major version

There is no easy way of doing this, Cloudnative-PG does not support upgrading major versions.

Checklist:
- [ ] Create new manifests for a new cluster in `kubernetes/main/apps/databases/cloudnative-pg/clusters`. Don't forget to add version to names.
  - [ ] DO NOT add a new loadbalancer just yet.
  - [ ] See https://cloudnative-pg.io/documentation/1.20/database_import/ for more information.
- [ ] Scale down services that uses postgres
- [ ] Create a new database backup: `kubectl create job --from=cronjob/postgres-backup -n databases major-upgrade-pg-backup`
- [ ] Deploy the new cluster.
- [ ] Update `ext-postgres-operator` config to start using the new cluster
- [ ] Add a new cronjob for `simple-pg-backup` with matching version.
- [ ] Migrate each service to the new cluster and don't forget to move backups from old version to new version.
- [ ] Delete the old postgres cluster by removing the manifests in `kubernetes/main/apps/databases/cloudnative-pg/clusters`.
- [ ] Deploy new loadbalancer

## Reset Rook Ceph cluster

I ran in to an issue where I had to reset the Rook-Ceph cluster due to restructuring the repo. I should have been more careful but it was also a learning experience. To fully reset the cluster I had to go through the following steps.:

* Suspend Flux reconciliations: `flux suspend reconciliation kustomization rook-ceph-cluster` and `flux suspend reconciliation kustomization rook-ceph-operator`
* Delete the file system: `kubectl delete cephfilesystem -n rook-ceph myfs`
* Might need to handle finalizers in some caes: `kubectl patch cephfilesystem -n rook-ceph myfs -p '{"metadata":{"finalizers":[]}}' --type=merge`
* Delete the cluster: `kubectl delete cephclusters.ceph.rook.io -n rook-ceph rook-ceph`
* Handle cluster finalizers: `kubectl patch cephclusters.ceph.rook.io -n rook-ceph rook-ceph -p '{"metadata":{"finalizers":[]}}' --type=merge`
* Delete all resources: `kubectl delete all -n rook-ceph --force --grace-period=0`
* Delete all CRDs that starts with ceph*
* Wipe disks: `kubectl apply -f kubernetes/tools/rook/wipe-job.yaml`
* Reset nodes and reboot: `talosctl reset --system-labels-to-wipe=STATE,EPHEMERAL --reboot --graceful=true -n <IP>`
  * Apply config again: `talosctl apply-config -n <IP> -f infrastructure/talos/clusterconfig/<CONFIG FILE>.yaml --insecure`

## /var is filling up

I had an issue where the /var directory on some of my nodes was filling up. Seems to have been containerd cache that didn't clear correctly. I fixed this by reseting the node and applying the Talos config again:

* Reset nodes and reboot: `talosctl reset --system-labels-to-wipe=STATE,EPHEMERAL --reboot --graceful=true -n <IP>`
* Apply config again: `talosctl apply-config -n <IP> -f infrastructure/talos/clusterconfig/<CONFIG FILE>.yaml --insecure`

## Upgrade Tube's Zigbee Gateway firmware

> Note to self: do not update over WIFI and remember to scale down zigbee2mqtt pod in the cluster

First upgrade the firmware:

- Goto devices esphome page: http://192.168.70.56/
- Toggle Prep the cc2652p2 for firmware update
- Run:

```
git clone https://github.com/JelmerT/cc2538-bsl.git

curl -L \
  -o CC1352P2_CC2652P_launchpad_coordinator_20210708.zip \
  https://github.com/Koenkk/Z-Stack-firmware/blob/master/coordinator/Z-Stack_3.x.0/bin/CC1352P2_CC2652P_launchpad_coordinator_20210708.zip?raw=true

unzip CC1352P2_CC2652P_launchpad_coordinator_20210708.zip

cd cc2538-bsl

python3 ./cc2538-bsl.py -p socket://192.168.70.56:6638 -evw ../CC1352P2_CC2652P_launchpad_coordinator_20210708.hex
```
