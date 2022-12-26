# Changelog

I'm not going to semver this repo since it wont work very well for this type of repo. I do however sometime wonder why others with similar repos makes the decitions that they do. Why they for example replaces one thing with another.
So I will use this changelog to highlight and motivate some of the changes I make.

## 2022-12-26

### Removed

- Removed Crowdsec because it causes a lot of issues where the Nginx Ingress controller becomes unresponse due to the fact that it can't connect to Crowdsec.

## 2022-12-11

### Changed

- Deployed EMQx-operator. Motivation: the old EMQx cluster that was deployed using Helm was a pain to update to new versions since it had to be teared down and then brought back up again with downtime.

## 2022-10-24

### Added

- Deployed [k8s-gateway](https://github.com/ori-edge/k8s_gateway)

### Deleted

- Removed Botkube. Motivation: I get all the info I need from the other monitoring tools that is running in the cluster.

## 2022-10-11

### Changed

- Re-organized large parts of the file and kustomization structure in the repo and started depending more on the dependOn setting in Helm releases. Main motivation is that it makes it easier to maintain everything.

## 2022-10-04

### Changed

- Replace kubelet-serving-cert-approver with kubelet-csr-approver since it seems to be more maintained

### Deleted

- Remove hajimari since I never use it.

## 2022-09-26

### Added

- Added monitoring using Prometheus, Grafana, Thanos & Loki. Will add more later on.
- Deployed [Radicale](https://radicale.org). Still testing this. Will probably replace Nextcloud Caldav with this soon.

### Changed

- Upgraded Kubernetes to version 1.25.2
- Upgraded Talos to version 1.2.3
- Moved Postgres to a Docker container on my NAS due to [Cloudnative-PG](https://cloudnative-pg.io/) currently not supporting Kubernetes version 1.25.x.
  Will move back as soon as [Cloudnative-PG](https://cloudnative-pg.io/) releases a compatible version.
- Migrated away from k8s-at-home Helm charts and Docker images since those repos has been archived/deprecated.

## 2022-08-05

### Fixed

- Reorganized `metallb` files and also fixed the CRD issue where the flux reconciliation would fail since the CRDs was created by the helm chart.
  CRDs are now included in the `kustomization.yaml` file instead.
- Enabled Hubble for Cilium.

### Added

- Added [Kyverno](https://kyverno.io/)
- Added Kyverno policy handling External-dns annotations on Ingresses
- Added Kyverno policy removing cpu limits
- Testing namespace
- Added Minecraft server

### Changed

- Replaced [Kubegres](https://www.kubegres.io/) (Postgres operator) with [Cloudnative-PG](https://cloudnative-pg.io/).
  I did this change due to the fact that Kubegres has not been updated in a long time and Cloudnative-PG seems like a more robust solution.
- Removed CPU limits. After reading [For the love of god, stop using CPU limits on Kubernetes](https://home.robusta.dev/blog/stop-using-cpu-limits/)
  I realized that I should remove CPU limits.
- Moved CRDs to where they belong. I never liked the directory structure for CRDs and I didn't like using Flux git resources to manage them.
  Now we include the CRDs in the `kustomization.yaml` instead.
- Moved namespace manifests from `config` directory.
