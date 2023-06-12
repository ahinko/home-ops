# Kubernetes on NAS

I want to use my NAS as a worker node in the Kubernetes cluster. There where some things to concider since the cluster was bootstrapped using Talos.

We have an Ansible role that installs and configures the NAS for Kubernetes but the role does NOT join the NAS as a worker node. Currently we need to do that manually.

## Steps
- Run `talosctl -n 192.168.20.24 copy /etc/kubernetes .`  to copy what we need from one of the existing worker nodes.
- Copy the following files to `/etc/kubernetes` on the NAS: `bootstrap-kubeconfig`, `kubelet.yaml`, `pki/ca.crt`.
- Add a new line to kubelet.yaml: `serverTLSBootstrap: true`
- Edit `/etc/systemd/system/kubelet.service.d/10-kubeadm.conf`:

```
# Note: This dropin only works with kubeadm and kubelet v1.11+
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubeconfig --kubeconfig=/etc/kubernetes/kubeconfig-kubelet --cgroup-driver=systemd"
Environment="KUBELET_CONFIG_ARGS=--config=/etc/kubernetes/kubelet.yaml"
# This is a file that "kubeadm init" and "kubeadm join" generates at runtime, populating the KUBELET_KUBEADM_ARGS variable dynamically
#EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
# This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably, the user should use
# the .NodeRegistration.KubeletExtraArgs object in the configuration files instead. KUBELET_EXTRA_ARGS should be sourced from this file.
EnvironmentFile=-/etc/default/kubelet
ExecStart=
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS
```

- `systemctl daemon-reload`
- Not sure if this is needed: `systemctl restart kubelet.service`
