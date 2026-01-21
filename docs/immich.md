# Immich

## VectorCord upgrades
After upgrading the VectorCord extension in the cnpg cluster, reindexing is required. See <https://docs.immich.app/administration/postgres-standalone#updating-vectorchord>.

```sql
ALTER EXTENSION vchord UPDATE;
REINDEX INDEX face_index;
REINDEX INDEX clip_index;
```

Using the cluster's pgadmin deployment is a good way to do this.
