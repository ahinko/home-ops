# Hosts

A large part of my homelab consists of my Kubernetes cluster that runs on 6 nodes:
* 4 Intel NUCs running Talos.
* 2 RPi4 running Talos.
* 1 whitebox that mainly works as a NAS but is also part of the K8s cluster and runs Talos.

Besides these nodes I also have a few smaller hosts that handles simpler tasks:
* PiKVM is a RPi4 with a POE hat and a HDMI to CSI-2 bridge. It's running PiKVM-OS and it's connected to a TESmart 8 Port KVM Switch.
* pihut is a RPi4 with a POE hat running Ubuntu 23.04 and it's connected to two Eaton 3S UPS. NUT is running in two separate Docker containers, one for each UPS. Home Assistant connects to these two containers to collect stats. Future plans include setting up automatic shutdown of nodes.
* zwave-coordinator is a RPi Zero W Rev 1.1 with a POE hat running Raspbian 11 and a Zwave-stick connected through USB. ser2net is installed so that Zwave-JS can connect to the USB stick.

I haven't set up any gitops flow to keep them up to date for various reasons and I also tend to not wanting to mess with these because I heavily rely on them being online:
* I haven't found a good way to do this for PiKVM and to quote the docs: "This is ONLY recommended if you need a feature...".
* The zwave-coordinator doesn't have many things running on it but an apt update should be enough but I would only do that if I absolutely need and when I have time to fix any issues that might occur. My smart home relies heavily on this host being online.

Kronos acts as a backup server that mostly is powered of and only powered on a weekly basis. Znapzend sends ZFS snapshots when Kronos is up and running. Kronos runs on Ubuntu 23.10 and its also a whitebox.
