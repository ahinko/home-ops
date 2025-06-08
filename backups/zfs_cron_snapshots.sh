#!/bin/bash
POOL=pool
SNAPSHOT_NAME=`date +%Y-%m-%d-%H%M%S`
/usr/sbin/zfs snapshot -r ${POOL}@${SNAPSHOT_NAME}
