# Provision bare metal nodes & Kubernetes

> **This document is out of date, an updated version will be available shortly**

## 1. Install needed tools

The first thing we need to do is to install some tools. Start by installing [Brew](https://brew.sh/) and [Taskfiles](https://taskfile.dev) after that we can use Taskfile to do a lot of the things we need to do.
For example: the remaining tools we need can be installed by running:

```shell
task tools:install
```

This will install the tools we need like `kubectl`, `talosctl` & `talhelper`.

## 1.1 SOPS

SOPS is a way of keeping our secrets encrypted so we can commit them to git. These encrypted secrets are then decrypted before they are applied to the Kubernetes cluster.

To generate and start using a new encyption key run the following command on your workstation:

```shell
age-keygen -o homelab.agekey
```

## 2. Prepare hardware

I use a mix of Raspberry Pi 4:s and Intel NUCs for my cluster.

### 2.1 Raspberry Pi

So what I have done is to prepare my Raspberry Pis for USB boot (use Google for more information about this). Each Raspberry Pi has a SSD attached using USB.
But first I connect the SSD (using USB) to my laptop and then I write Talos to that disk by running:

```shell
task talos:write-talos-arm64-to-usb
```

The task will ask witch disk to write to. Use `diskutil list` to identify the attached disk. After that I attach the SSD to the Raspberry Pi and Talos will boot in to maintenace mode.

### 2.1 x86

For my Intel NUC:s I write Talos to a USB stick using:

```shell
task talos:write-talos-amd64-to-usb
```

After that I attach the USB stick to the NUC, boot it from the USB drive and Talos will boot in to maintenace mode. When Talos has booted up you can remove the USB stick and attach it to another node if wanted.

## 3. Talos

### 3.1 Prepare configs

I use the excellent tool [Talhelper](https://github.com/budimanjojo/talhelper) to handle Talos config files. We start by modifying [talconfig.yaml](../../infrastructure/talos/clusterconfig/talosconfig) to match our needs.
It's quite straight forward and we can use the [Talos documentation](https://www.talos.dev/latest/reference/configuration/) as a reference.


While you are at it you can also take a look at the [cluster secrets file as well](../../kubernetes/flux/config/sops.cluster-secrets.yaml).

## 3.2 Apply config & bootstrap cluster

Time to boostrap you cluster. Start with applying the talos config for one of your control planes:

* `talosctl apply-config -n <IP> -f clusterconfig/metal-<node>.yaml --insecure`
* Use `talosctl dmesg -n <IP> -f` and when you see a message about bootstraping etcd you need to run: `talosctl bootstrap -n <IP>`
* When the boostraping has completed you can apply the rest of the nodes configs using the same command as above.
* `talosctl kubeconfig ~/.kube/configs/metal -n <IP>``
* `kubectl config rename-context admin@metal metal``

## 4. Flux

* Install Flux in the cluster: `k apply --server-side --kustomize kubernetes/bootstrap/`

### 4.1 Create needed secrets

Next we need to set up a few secrets:

* `export GITHUB_USER=<your-github-username>`
* `flux create secret git homelab-flux-secret --url=ssh://git@github.com/<username>/<repo>`
* You can find a deploy key in the output from the above command. Add it here: https://github.com/<username>/<repo>/settings/keys
* Deploy SOPS key: `cat homelab.agekey | kubectl create secret generic sops-age --namespace=flux-system --from-file=age.agekey=/dev/stdin`

### 4.2 Sync repo & cluster

Time to start Flux to do its thing. Please note that if you would deploy everything at the same time you will run in to problems. There are a few "catch 22" scenarios in the setup. What I do before triggering the command below is to prevent most of the different deployments from deploying and only do the essentials first. For example, ingress is needed by many deployments. Same for Rook/Ceph and Postgres. In many cases I also want to restore backups of PVCs and databases before deployments can run.

It's a good idea to disable any monitoring until you have Prometheus and Thanos up and running.

* `k apply --server-side --kustomize kubernetes/flux/vars/`
* `k apply --server-side --kustomize kubernetes/flux/config/`

## 5. Terraform

We need to run Terraform.

* Start with Cloudflare, it should work without issues.
* Minio will require that you have Ingress and Minio working before it's possible to complete it without issues.

## 6. Restore backups

`TODO`

## 7. Additional notes

### 7.1 Trick: how to reset a Talos node to maintenance mode without a USB stick

Sometimes I need to reset a Talos node and make sure the install disk is wiped and finally make Talos boot in to maintenance mode. This is easier than having to plug in a USB drive in different nodes.
Since I have my nodes connected to a KVM that I can access remotely I can reset a node without being physically at the node.

This can be achieved by setting a kernel boot parameter. You can do this by pressing `e` when the boot menu is shown. You will be able to edit the kernel boot parameters.
Go to the line staring with `linux` and add `talos.experimental.wipe=system` at the end of the line.
Press `ctrl + x` and the node will boot in to maintenace mode and wipe the system disk.

References:

- [How do I add a kernel boot parameter](https://askubuntu.com/questions/19486/how-do-i-add-a-kernel-boot-parameter)
- [Resetting a machine](https://www.talos.dev/v1.1/talos-guides/resetting-a-machine/)

### 7.2 Manage kubeconfigs

I have created `~/.kube/clusters` where I store each `kubeconfig` in a separate file.

I use [Fish shell](https://fishshell.com/) and to handle this I have to add this line in `~/.config/fish/config.fish`.

```shell
set -gx KUBECONFIG "$(find ~/.kube/configs -type f 2>/dev/null | xargs -I % echo -n "%:")"
```

If you are using ZSH you should add the following code to your `~/.zshrc` file to load each file from the config directory:

```shell
function set-kubeconfig {
  # Sets the KUBECONFIG environment variable to a dynamic concatentation of everything
  # under ~/.kube/configs/*
  # Does NOT overwrite KUBECONFIG if it does not include a ":" (was most likely explicitly set)

  sentinel=":"
  if [ -z "$KUBECONFIG" ] || [[ $KUBECONFIG =~ $sentinel ]]; then
    # There is a colon in KUBECONFIG; it was automatically set
    if [ -d ~/.kube/configs ]; then
      export KUBECONFIG=~/.kube/config:$(find ~/.kube/configs -type f 2>/dev/null | xargs -I % echo -n "%:")
    fi
  fi
}

add-zsh-hook precmd set-kubeconfig
```

I highly recommend to manage kubeconfigs this way since my `taskfiles` and `scripts` relies on this and files will be automatically be created in `~/.kube/clusters`.
