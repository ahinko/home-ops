# Postgres

## Bootstap new cluster from backup (untested)

Modify the `cluster.yaml` file and add the following:

```yaml
  bootstrap:
    recovery:
      source: origin

  externalClusters:
    - name: origin
      plugin:
        name: barman-cloud.cloudnative-pg.io
      parameters:
        barmanObjectName: postgres18-local-ceph # same as in old cluster
        serverName: postgres18-v2 # same as in old cluster
```

Keep `servername: postgres18-v2`

## Clean up R2 storage
```shell
aws configure
aws s3 rm s3://<bucket> --endpoint-url https://<endpoint>.eu.r2.cloudflarestorage.com --recursive --dryrun
```
