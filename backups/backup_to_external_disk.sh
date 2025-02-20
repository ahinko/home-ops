#!/bin/bash

kubectl config use-context main
kubectl apply -f ./deployment.yaml

echo "Waiting for pod..."
sleep 3

POD=$(kubectl get pod -l app=zfs-backup -o jsonpath="{.items[0].metadata.name}")

kubectl wait --for=condition=Ready pod/${POD}

DATASETS=( minio samba immich/library games )
TARGET_PATH=/Volumes/Backup

# Loop through datasets
for dataset in "${DATASETS[@]}";
do
        echo "Rysnc ${dataset} to ${TARGET_PATH}"
        kubectl rsync -- -a -v --progress --delete ${POD}:/backup/${dataset} ${TARGET_PATH}
done

sleep 15

kubectl delete -f ./deployment.yaml

echo "Backup done!"
