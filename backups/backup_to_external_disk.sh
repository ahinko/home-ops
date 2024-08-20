#!/bin/bash

kubectl config use-context storage
kubectl apply -f ./deployment.yaml

echo "Waiting for pod..."
sleep 15

POD=$(kubectl get pod -l app=zfs-backup -o jsonpath="{.items[0].metadata.name}")

DATASETS=( minio samba immich/library )
TARGET_PATH=/Volumes/Backup

# Loop through datasets
for dataset in "${DATASETS[@]}";
do
        echo "Rysnc ${dataset} to ${TARGET_PATH}"
        kubectl rsync -- -a -v --progress --delete ${POD}:/backup/${dataset} ${TARGET_PATH}
done

kubectl delete -f ./deployment.yaml

echo "Backup done!"
