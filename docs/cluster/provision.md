# Provision bare metal nodes & Kubernetes

## 1. Install needed tools

The first thing we need to do is to install some tools. Start by installing [Brew](https://brew.sh/) and [Taskfiles](https://taskfile.dev) after that we can use Taskfile to do a lot of the things we need to do.
For example: the remaining tools we need can be installed by running:

```shell
task tools:install
```

This will install the tools we need like `kubectl`, `talosctl` & `talhelper`.

We also need to create a `.env` file in the root of this project. See `.env-example` for which info is needed.

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

## 3. Modify Talos configs

I use the excelent tool [Talhelper](https://github.com/budimanjojo/talhelper) to handle Talos config files. We start by modifying [talconfig.yaml](../../infrastructure/talos/clusterconfig/talosconfig) to match our needs.
It's quite straight forward and we can use the [Talos documentation](https://www.talos.dev/latest/reference/configuration/) as a reference.

Make sure your [cluster-settings](../../kubernetes/config/cluster-settings.yaml) file matches your Talos configuration (mainly IP address for the cluster endpoint).

While you are at it you can also take a look at the [cluster secrets file as well](../../kubernetes/config/sops.cluster-secrets.yaml).

## 4. Run provision script

I use the VIP (Virtual IP) functionallity that is built in to Talos. But there is one issue with this. There is a chicken and egg problem where the VIP will not be available unless at least two controlplane nodes has been provisioned.
But if we set the VIP as the endpoint for the controlplane (which we actually want to do) the nodes will not be able to create the cluster.

So what this provision script does is that it first modifies the Talos configuration files to first use one of the controlplane nodes as the endpoint so that the cluster can be created.

The script will provision the controlplane nodes first and bootstrap the cluster. After making sure that the cluster is up and running the script will revert the change made to the controlplane endpoint in the Talos configuration
files and after that the script will both provision any worker nodes and as well apply the reverted configuration to the controlplane nodes.

When we are happy with the configuration we run:

*** DISCLAMER: this script has not been tested in a while. No guaranties that it will work. ***

```shell
task k8s:provision
```

When the cluster is up and running the script will fetch the `kubeconfig`. See my notes regarding how I handle my `kubeconfigs` further down in this document.

Last but not least the provision script will provision Flux to the cluster.

## 5. Run Terraform

We use Terraform for provisioning and keeping our Cloudflare settings up to date. Terraform will set up the domain we use as well as creating a few Kubernetes secrets for Cloudflare API tokens that is used by a few services running on the cluster.
See [expose-services.md](expose-services.md) for more information.

Therefor you need to modify the [secrets file](../../infrastructure/terraform/cloudflare/sops.secrets.yaml) to set it up according to your needs.

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

### 7.2 Rook/Ceph issue with prepare-osd pods

I had issues where the prepare-osd pods failed due to "unparsable uuid". I did two things at the same time when the issue was fixed so I'm not sure exactly what fixed it:

- I downgraded ceph to version v16.2.7
- I removed the resource limitations.

I have a vague recollection that I have had a similar issue before and if I remember correctly the that was also fixed by using a specific version of ceph. But I do not remember which versions I tested with that time.

### 7.3 Manage kubeconfigs

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
