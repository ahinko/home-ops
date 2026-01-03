# Snippets & notes

Snippets and notes about how to fix problems.

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

## Postgres, pgvecto.rs and Immich

If we get the `pg_basebackup: error: backup failed: ERROR:  file name too long for tar format` error then we need to:

```SQL
DROP INDEX clip_index;
DROP INDEX face_index;
```

Get all replicas up and running and then:

```SQL
SET vectors.pgvector_compatibility=on;
CREATE INDEX IF NOT EXISTS clip_index ON smart_search
USING hnsw (embedding vector_cosine_ops)
WITH (ef_construction = 300, m = 16);

CREATE INDEX IF NOT EXISTS face_index ON face_search
USING hnsw (embedding vector_cosine_ops)
WITH (ef_construction = 300, m = 16);
```

## Rook/ceph mds behind on trimming

Fixed this by changeing: `k rook-ceph ceph config set mds mds_log_max_segments 256`

Use `k rook-ceph ceph health detail` to get how far behind it is.
