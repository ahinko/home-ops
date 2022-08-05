# Changelog

I'm not going to semver this repo since it wont work very well for this type of repo. I do however sometime wonder why others with similar repos makes the decitions that they do. Why they for example replaces one thing with another. So I will use this changelog to highlight and motivate some of the changes I make.

## 2022-08-05

### Fixed
- Reorganized `metallb` files and also fixed the CRD issue where the flux reconciliation would fail since the CRDs was created by the helm chart. CRDs are now included in the `kustomization.yaml` file instead.
- Enabled Hubble for Cilium.

### Added
- Added [Kyverno](https://kyverno.io/)
- Added Kyverno policy handling External-dns annotations on Ingresses
- Added Kyverno policy removing cpu limits
- Testing namespace
- Added Minecraft server

### Changed
- Replaced [Kubegres](https://www.kubegres.io/) (Postgres operator) with [Cloudnative-PG](https://cloudnative-pg.io/). I did this change due to the fact that Kubegres has not been updated in a long time and Cloudnative-PG seems like a more robust solution.
- Removed CPU limits. After reading [For the love of god, stop using CPU limits on Kubernetes](https://home.robusta.dev/blog/stop-using-cpu-limits/) I realized that I should remove CPU limits.
- Moved CRDs to where they belong. I never liked the directory structure for CRDs and I didn't like using Flux git resources to manage them. Now we include the CRDs in the `kustomization.yaml` instead.
- Moved namespace manifests from `config` directory.
