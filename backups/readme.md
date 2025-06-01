# Backups

Backups are important!

## Backup server
- Clone this repo to /homelab
- `cp kubectl-rsync ~/.kube/plugins/`
- `nano ~/.config/fish/config.fish`, add: `fish_add_path ~/.kube/plugins`
- Edit crontab and add this:
-
```shell
PATH="/root/.kube/plugins:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"

0 */6 * * *   /homelab/backups/backup_to_external_disk.sh /homelab/backups/backup_jobs_kronos.yaml
0 0 * * *     /homelab/backups/zfs_cron_snapshots.sh
```

## Backup to local disk
Run `./backups/backup_to_external_disk.sh ./backups/backup_jobs.yaml`
