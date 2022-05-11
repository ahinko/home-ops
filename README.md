# 🏡 🧪 Homelab + Gitops

🚧 **Under construction, please have some patience**

Welcome to my repo where I maintain everything related to my homelab which adheres to Infrastructure as Code (IaC) and GitOps practices where possible. This allows me to have a single source of written truth for my homelab, declaring how and where I want it setup. I have a Kubernetes cluster that runs most of the services in my homelab but I also have a few services running as Docker containers on my NAS.

This allows me to:
* Version control my changes, allowing easy rollback of breaking patches/tinkering/etc
* Allow for easy reinstall/disaster recovery of a cluster, as everything except persistent data is defined here.
* Version control and declare hardware provisioning (Now using Sidero & Talos), ensuring repeatable and robust hardware configuration.
* This can be achieved with tools such as Terraform and Ansible for those wanting to use a more standard OS & deployment.
* With Sidero and Talos, I can define and provision a cluster by plugging nodes into the network, and having them network PXE boot, install the OS Talos, and have a configuration file applied to them. This automates and watches my cluster, with no manual intervention required.

## 🧪 Why a homelab?

My motivation for having a homelab is that it is a great way to learn and educate myself and pick up new skills that I might have use for in at my work.

Besides that I'm also running some services that are used daily by myself, family & friends.

## ✨ Main features
These are what I consider the main features of my homelab. You can also see this list as an index to the documentation. If you want to set up your own cluster and use my repo as a guide I suggest that you read through the documentation in this order:

- [x] [Automated provisioning of Management cluster and it's bare metal nodes](docs/management-cluster.md)
- [ ] 🚧 Automated bare metal provisioning of Kubernetes nodes
- [ ] 🚧 Automated Kubernetes installation and management
- [ ] 🚧 Installing and managing applications using GitOps
- [ ] 🚧 Automatic rolling upgrade for OS and Kubernetes
- [ ] 🚧 Automatically update apps (with approval)
- [ ] 🚧 Modular architecture, easy to add or remove features/components
- [ ] Automated certificate management
- [ ] Automatically update DNS records for exposed services
- [ ] Distributed storage
- [ ] Monitoring and alerting
- [ ] Automated offsite backups

## 🤖 Automate all the things
Why do things manually when you can automate it? I try to automate as many aspects of my homelab as possible.

I have set up [Sidero](sidero.md) to manage my main cluster. My main cluster uses [Talos](https://talos.dev) as its OS on all nodes. [Renovate](https://www.whitesourcesoftware.com/free-developer-tools/renovate) is set up to update the needed files when there are a new version of Talos or Kubernetes available. As soon as that pull request is merged in to the main branch [Flux](https://fluxcd.io) will update Sideros configuration and Sidero will then start updating the nodes.

The same principle applies to the main cluster when there are any new releases of anything running in the cluster. Renovate creates a pull request, I merge the pull request to the main branch and Flux will then update the configuration in the cluster and if a pod needs to be upgraded or restarted that will be done automatically.

Updates to the Docker containers running on my NAS are handled in a similar way. There is a clone of the repository on the NAS and when Renovate creates pull requests and when those are merged to the main branch a [cronjob](scripts/automatic-docker-updates.sh) pulls the updates and then does a `docker-compose up -d --build` to update the Docker containers.

I use [Ansible](https://ansible.com) to provision and configure other hardware in my homelab like my NAS, backup server and pikvm.

As a last resort I use [Taskfile](http://taskfile.dev) and write bash scripts to run repetitive tasks.
