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
