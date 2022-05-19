# Management cluster
This is the long version of how to set up the management cluster that manages the main Kubernetes cluster. This document contains explanations to how things work and background to some of the decisions that has been made.

## My setup
These are a few things that is good to know about since it will probably cause issues if you do not have the same setup.

### Network
I have one dedicated VLAN for all Kubernetes nodes. Nothing else is supposed to be running on this VLAN.

I decided to run a DHCP server on the Sidero cluster, this gives me more flexibility regarding iPXE than using the DHCP server on my router.

In my router settings for the VLAN the DHCP setting is set to `DHCP relay` and point to the Sidero management node.

**I have not found a way to modify the network configuration in Talos before booting the Sidero node so until Sidero has been provisioned I have my router act as the DHCP server for the VLAN.** After Sidero has been provisionend I update my router settings to `DHCP relay`.

All the nodes in the main cluster is set to always network boot since Sidero runs an iPXE server that they can connect to.

### Manage kubeconfigs
We will have at least two `kubeconfigs` to deal with, one for Sidero and one for the main cluster. I have created `~/.kube/clusters` where I store each `kubeconfig` in a separate file.

I use [Fish shell](https://fishshell.com/) and to handle this I have to add this line in `~/.config/fish/config.fish`.

```shell
$ set -gx KUBECONFIG "$(find ~/.kube/configs -type f 2>/dev/null | xargs -I % echo -n "%:")"
```

If you are using ZSH you should add the following code to my `~/.zshrc` file to load each file from the config directory:

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

## Install needed CLI & tools

Install [Taskfile](https://taskfile.dev)
```shell
$ brew install go-task/tap/go-task
```

Install other CLI and & tools
```shell
$ task tools:install
```

### SOPS
SOPS is a way of keeping our secrets encrypted so we can commit them to git. These encrypted secrets are then decrypted before they are applied to the Kubernetes cluster.

To generate and start using a new encyption key run the following commands on your workstation:
```shell
$ age-keygen -o homelab.agekey
```

## Provision Sidero management cluster
> [Talos](https://talos.dev) is a Linux OS designed for secure, immutable, and minimal installations on both baremetal hardware and cloud-native environments. Talos is available on both amd64 and various single board computers, like the Raspberry Pi.

> [Sidero](https://sidero.dev) Metal uses Cluster API to automate bare metal server provisioning and lifecycle management. Clusters are provisioned (or re-provisioned) automatically, delivering a secure Kubernetes deployment.
>
> Sidero includes a metadata service, PXE and TFTP servers, as well as BMC and IPMI management for automation.

My initial thought was to skip Sidero since it adds more complexity and I will only have one cluster so I did not see a point in running it. But then I watched Sidero labs Youtube video [Hack Sesh: K8s@Home Edition](https://www.youtube.com/watch?v=ZbXwTXSI9lk) that goes through the whole process of setting up Sidero and in the last 10 minutes you can see what made me decide to use Sidero: upgrading Talos and Kubernetes on my cluster by editing and committing a few files to the git repo. Sidero will then handle the upgrade automatically.

We use a Raspberry Pi 4 4GB (arm64) with a POE hat and an SSD for storage for our Sidero management plane.

### Prepare RPi for USB boot
#### Updating the EEPROM
At least version `v2020.09.03-138a1` of the bootloader (`rpi-eeprom`) is required. To update the bootloader we will need an SD card. Insert the SD card into your computer and use Raspberry Pi Imager to install the bootloader on it (select Operating System > Misc utility images > Bootloader > USB Boot).

Remove the SD card from your local machine and insert it into the Raspberry Pi. Power the Raspberry Pi on, and wait at least 10 seconds. If successful, the green LED light will blink rapidly (forever), otherwise an error pattern will be displayed. If an HDMI display is attached to the port closest to the power/USB-C port, the screen will display green for success or red if a failure occurs. Power off the Raspberry Pi and remove the SD card from it.

> **Note**: Updating the bootloader only needs to be done once.

The Raspberry Pi will boot from USB/SSD if one exist, else it will try and boot from SD Card.

### Prepare SSD with Talos
Prepare the SSD with the Talos RPi4 image:

```shell
task talos:prepare-rpi
```

Connect the SSD to the Raspberry Pi and boot it up. Make sure the system booted from the correct media. Talos should drop into maintenance mode printing the acquired IP address. Notice the IP address you will need it soon.

### Environment variables and secrets
Create/update an `.env` file and add the IP address that the Raspberry Pi got so we can use it as the Sidero endpoint. Also add the IP address to a nameserver/dns server that you want to use.

```env
SIDERO_ENDPOINT=192.168.25.10

METAL_CLUSTER_NODES="192.168.25.21 192.168.25.22 192.168.25.23 192.168.25.24"
METAL_CLUSTER_CP_LB=192.168.5.20

VLAN_NAMESERVER=192.168.25.1
VLAN_GATEWAY=192.168.25.1

GITHUB_USER=username
GITHUB_TOKEN=******

KUBECTL_CONTEXT_SIDERO=sidero
KUBECTL_CONTEXT_METAL=metal
```

Update/verify the two `cluster-settings.yaml` files:
- [../kubernetes/management/base/cluster-settings.yaml](kubernetes/management/base/cluster-settings.yaml)
- [../kubernetes/metal/base/cluster-settings.yaml](kubernetes/management/metal/cluster-settings.yaml)

And while we are at it you might as well update/verify the secrets files for the clusters:
- [../kubernetes/management/base/sops.cluster-secrets.yaml](kubernetes/management/base/sops.cluster-secrets.yaml)
- [../kubernetes/metal/base/sops.cluster-secrets.yaml](kubernetes/management/metal/sops.cluster-secrets.yaml)

### Install Sidero
Time to bootstrap Talos and install Sidero. This script aims at automating as much as possible by using the variables in `.env` and then run the different needed commands to bootstrap Talos and install Sidero.

```shell
$ task sidero:provision
```

#### Known issues
If you encounter the following error, this is caused by a rename of Sideros GitHub org from talos-systems to siderolabs.

> Fetching providers
> Error: failed to get provider components for the "talos" provider: target namespace can't be defaulted. Please specify a target namespace

This can be worked around by adding the following to ~/.cluster-api/clusterctl.yaml and rerunning the init command:

```yaml
providers:
  - name: "talos"
    url: "https://github.com/siderolabs/cluster-api-bootstrap-provider-talos/releases/latest/bootstrap-components.yaml"
    type: "BootstrapProvider"
  - name: "talos"
    url: "https://github.com/siderolabs/cluster-api-control-plane-provider-talos/releases/latest/control-plane-components.yaml"
    type: "ControlPlaneProvider"
  - name: "sidero"
    url: "https://github.com/siderolabs/sidero/releases/latest/infrastructure-components.yaml"
    type: "InfrastructureProvider"
```

### Change DHCP settings
First look at the files in `kubernetes/management/apps/kube-system/dhcpd` and update any IP addresses to match your environment. I would also recommend modifying the static IPs in [dhcpd-config.yaml](../kubernetes/management/apps/kube-system/dhcpd/dhcpd-config.yaml) to match your environment. Commit and push your changes so that they are pushed to the cluster.

Also update your DHCP router settings and set the IP address to the IP address of the Sidero node (same as the environment variable $SIDERO_ENDPOINT).

### Verify installation
The Sidero management cluster should now be up and running. You can verify that everything is working by listing all the running pods on the cluster:

```shell
$ kubectx sidero
$ kubectl get pods -A
```

Next step is to [bootstrap our metal cluster]().
