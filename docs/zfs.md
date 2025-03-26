# ZFS

## Znapzend

```
znapzendzetup create --recursive --mbuffer=/usr/bin/mbuffer \
   --mbuffersize=1G --tsformat='%Y-%m-%d-%H%M%S' \
   SRC '30d=>1d' pool/immich \
   DST:a '30d=>1d' root@192.168.20.4:pool/immich
```
