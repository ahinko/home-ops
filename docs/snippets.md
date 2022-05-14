# Snippets & notes
Snippets and notes about how to fix problems where a [task](.taskfiles/) was to complex to set up.

## Postgres restore backup

Find the backup you want to restore and check the file. **I usually do not restore postgres and replication roles etc so I remove those from the file.**

Restore backup: `psql -h POSTGRES_LB_SVC -U USERNAME -W -d DATABASE < RESTORE_FILENAME`
