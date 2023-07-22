# ZFS

## Znapzend

```
znapzendzetup create --recursive --mbuffer=/usr/bin/mbuffer \
   --mbuffersize=1G --tsformat='%Y-%m-%d-%H%M%S' \
   SRC '30d=>1d' tank/immich \
   DST:a '30d=>1d' root@kronos:pool/immich
```
