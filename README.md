# 🏡 🧪 Homelab + Gitops

🚧 **Under construction, please have some patience**

Welcome to my repo where I maintain everything related to my homelab which adheres to Infrastructure as Code (IaC) and GitOps practices where possible. This allows me to have a single source of written truth for my homelab, declaring how and where I want it setup. I have a Kubernetes cluster that runs most of the services in my homelab but I also have a few services running as Docker containers on my NAS.

This allows me to:
* Version control my changes, allowing easy rollback of breaking patches/tinkering/etc
* Allow for easy reinstall/disaster recovery of a cluster, as everything except persistent data is defined here.
* Version control and declare hardware provisioning (Now using Sidero & Talos), ensuring repeatable and robust hardware configuration.
* This can be achieved with tools such as Terraform and Ansible for those wanting to use a more standard OS & deployment.
* With Sidero and Talos, I can define and provision a cluster by plugging nodes into the network, and having them network PXE boot, install the OS Talos, and have a configuration file applied to them. This automates and watches my cluster, with no manual intervention required.
* Sidero also manages Talos and Kubernetes updates. Renovate will create pull requests when new updates are available. When the pull requests are merged to the main branch Flux will update the manifests with the specified versions in the management cluster. Sidero will then update the metal nodes and restart them if needed.

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

* I use [Sidero](sidero.md) as a management cluster that manages my main cluster.
* [Talos](https://talos.dev) is the OS on all Kubernetes nodes.
* [Renovate](https://www.whitesourcesoftware.com/free-developer-tools/renovate) keeps track of third party dependencies and creates a pull request when there is something to update.
*  I then merge those pull requests in to the main branch
*  [Flux](https://fluxcd.io) will then update both the management cluster and the main cluster.
*  Sidero will start update  Kubernetes nodes in my main cluster if there are updates of the Talos OS or Kubernetes itself.
* If there are updates to any of the services I run in the main cluster those services will automatically be updated (and restarted if needed).

Updates to the Docker containers running on my NAS are handled in a similar way.

* There is a clone of the repository on the NAS
* A [cronjob](scripts/automatic-docker-updates.sh) pulls the updates and does a `docker-compose up -d --build` to update the Docker containers.

I use [Ansible](https://ansible.com) to provision and configure other hardware in my homelab like my NAS, backup server and pikvm.

As a last resort I use [Taskfile](http://taskfile.dev) and write bash scripts to run repetitive tasks.

## 🐳 Docker
I have a few services that I've choosen to host outside of the Kubernetes cluster. For example I host a [Minio](https://min.io) instance that is mainly used for backing up persistant volumes within the Kubernetes cluster.

I also host a [Plex](https://plex.tv) server that I wan't to run on the more powerfull server/NAS so there is no point in including that in the Kubernetes cluster and then force it to run on the specific server.

There is also a NFS and a Samba server running in Docker on the NAS for easier access to file shares, backups and media.

## 📓 Snippets & notes
Every now and then I run in to problems and I usually do one of two things when I fix them:

* I either create a [task](.taskfiles/) using Taskfile so it's easy to do the same thing over and over again
* Or [I write down the solution](docs/snippets.md). This is usually done when it's to complex to create a task for it.
