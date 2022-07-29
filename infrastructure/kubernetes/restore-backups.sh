#!/bin/bash

. $(dirname "$0")/common.sh

need kubectl
need flux

# Check that flux is running in the cluster
FLUX=$(kubectl get pods -n flux-system -o json | jq -r '.items[] | select(.status.conditions[].type=="Ready") | .metadata.name')

if [[ $FLUX == '' ]]; then
  die "Flux not running. Exiting..."
fi

ROOK_PVCS=$(kubectl get pvc -A -o=json | jq -r '.items[] | select(.spec.storageClassName=="rook-cephfs") | .metadata.name')

for PVC in $ROOK_PVCS; do
  PVC=$(echo $PVC | sed 's/"//g')

  DEPLOYMENTS=$(kubectl get deployments.apps -A -o=json | jq -c '.items[] | {name: .metadata.name, namespace: .metadata.namespace, claimName: .spec.template.spec |  select( has ("volumes") ).volumes[] | select( has ("persistentVolumeClaim") ).persistentVolumeClaim.claimName } | select(.claimName=="'$PVC'")')

  if [ -z "$DEPLOYMENTS" ]; then
    DEPLOYMENTS=$(kubectl get statefulsets.apps -A -o=json | jq -c '.items[] | {name: .metadata.name, namespace: .metadata.namespace, claimName: .spec.template.spec |  select( has ("volumes") ).volumes[] | select( has ("persistentVolumeClaim") ).persistentVolumeClaim.claimName } | select(.claimName=="'$PVC'")')
  fi

  # Find all deployments using rook/ceph volumes
  for DEPLOYMENT in $DEPLOYMENTS ; do
    DEPLOYMENT_NAME=$(jq -r '.name' <<< $DEPLOYMENT)
    NAMESPACE=$(jq -r '.namespace' <<< $DEPLOYMENT)

    if [ -f "$REPO_ROOT/kubernetes/tools/restore-backups/$DEPLOYMENT_NAME-job.yaml" ]; then
      echo "---"
      echo "Scaling down $DEPLOYMENT_NAME in namespace $NAMESPACE"
      # Scale down deployment
      flux suspend hr -n $NAMESPACE $DEPLOYMENT_NAME
      kubectl scale -n $NAMESPACE deploy/$DEPLOYMENT_NAME --replicas 0

      # Run restore job with force = true/1
      echo "Restoring backup"
      kubectl apply -f $REPO_ROOT/kubernetes/tools/restore-backups/$DEPLOYMENT_NAME-job.yaml

      # Wait for restore job to finish
      echo "Waiting for restoration to complete"
      kubectl -n $NAMESPACE wait --for=condition=complete job/restore-$DEPLOYMENT_NAME

      # Scale up deployment again
      echo "Scaling up $DEPLOYMENT_NAME in namespace $NAMESPACE"
      flux resume hr -n $NAMESPACE $DEPLOYMENT_NAME
      kubectl scale -n $NAMESPACE deploy/$DEPLOYMENT_NAME --replicas 1
    fi
  done
done
