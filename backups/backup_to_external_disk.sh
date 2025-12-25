#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 <config_file.yaml>"
    exit 1
fi

CONFIG_FILE="$1"

NUM_JOBS=$(yq eval '.jobs | length' "$CONFIG_FILE")

for ((i=0; i<NUM_JOBS; i++)); do
    NAMESPACE=$(yq eval ".jobs[$i].namespace" "$CONFIG_FILE")
    PVC=$(yq eval ".jobs[$i].pvc" "$CONFIG_FILE")
    DESTINATION_PATH=$(yq eval ".jobs[$i].destination_path" "$CONFIG_FILE")

    # Ensure destination path exists and is writable
    if [ ! -d "$DESTINATION_PATH" ]; then
      echo "Destination path '$DESTINATION_PATH' does not exist; attempting to create it..."
      if ! mkdir -p "$DESTINATION_PATH"; then
        echo "Error: Failed to create destination path '$DESTINATION_PATH'. Skipping this job."
        continue
      fi
      echo "Created destination path '$DESTINATION_PATH'."
    fi

    if [ ! -w "$DESTINATION_PATH" ]; then
      echo "Error: Destination path '$DESTINATION_PATH' is not writable. Skipping this job."
      continue
    fi

    echo "Backing up ${NAMESPACE}/${PVC} to ${DESTINATION_PATH}"

    # Apply the Pod manifest directly from stdin
    cat <<EOF | kubectl apply -f - -n ${NAMESPACE}
apiVersion: v1
kind: Pod
metadata:
  name: zfs-backup-${PVC}
  labels:
    app: zfs-backup-${PVC}
spec:
  nodeName: s01
  containers:
  - name: zfs-backup
    image: ghcr.io/ahinko/buoy:1.4.6
    command: ["/bin/bash", "-c", "--"]
    args: ["while true; do sleep 30; done;"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: ${PVC}
EOF

    echo "Waiting for pod..."
    sleep 30

    POD=$(kubectl get pod -n ${NAMESPACE} -l app=zfs-backup-${PVC} -o jsonpath="{.items[0].metadata.name}")

    kubectl wait --for=condition=Ready pod/${POD} -n ${NAMESPACE}

    echo "Rysnc data to ${DESTINATION_PATH}"
    kubectl rsync -n ${NAMESPACE} -- -a -v --progress --delete ${POD}:/data/ ${DESTINATION_PATH}

    sleep 10

    # Delete the Pod after backup
    kubectl delete pod ${POD} -n ${NAMESPACE}

    echo "Backup done!"
done
