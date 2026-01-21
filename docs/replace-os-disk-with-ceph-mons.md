# Talos Node Drive Replacement Checklist (with Rook/Ceph)

## Before Starting

- [ ] Identify which nodes are running mons:
  ```bash
  kubectl rook-ceph ceph mon dump
  ```
- [ ] Verify cluster is healthy:
  ```bash
  kubectl rook-ceph ceph status
  ```
- [ ] Set noout to prevent OSD rebalancing:
  ```bash
  kubectl rook-ceph ceph osd set noout
  ```

---

## Per-Node Procedure

Repeat for each node, one at a time.

### 1. Pre-replacement

- [ ] If node has a mon, remove it first:
  ```bash
  kubectl rook-ceph ceph mon remove <mon-id>
  ```
- [ ] Verify quorum (need 2/3 mons healthy):
  ```bash
  kubectl rook-ceph ceph status
  ```

### 2. Replace drive

- [ ] Physically replace the drive
- [ ] Reapply Talos config to the node
- [ ] Wait for node to boot and rejoin the cluster

### 3. Post-replacement

- [ ] Verify node is Ready:
  ```bash
  kubectl get nodes
  ```
- [ ] Wait for OSD to rejoin (if applicable):
  ```bash
  kubectl rook-ceph ceph osd tree
  ```
- [ ] Wait for mon to be redeployed (if applicable):
  ```bash
  kubectl rook-ceph ceph status
  ```
- [ ] Confirm 3 mons in quorum before proceeding to next node
- [ ] Wait 10-15 minutes for full stabilization

---

## After All Nodes Complete

- [ ] Unset noout:
  ```bash
  kubectl rook-ceph ceph osd unset noout
  ```
- [ ] Final health check:
  ```bash
  kubectl rook-ceph ceph status
  ```
- [ ] Verify all OSDs are up:
  ```bash
  kubectl rook-ceph ceph osd tree
  ```

---

## Important Reminders

- Always maintain quorum: 2 out of 3 mons must be up
- Do not rush — wait for each node to fully stabilize
- Start with the non-mon node if you want an easy warmup
- OSD data lives on the separate disk, it will rejoin automatically
- Mon data lives on the boot drive and must be removed/redeployed
