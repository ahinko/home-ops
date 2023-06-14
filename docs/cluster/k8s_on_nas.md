# Kubernetes on NAS

I want to use my NAS as a worker node in the Kubernetes cluster. There where some things to concider since the cluster was bootstrapped using Talos.

We have an Ansible role that installs and configures the NAS for Kubernetes but the role does NOT join the NAS as a worker node. Currently we need to do that manually.

## Steps
- Run `talosctl -n 192.168.20.24 copy /etc/kubernetes .`  to copy what we need from one of the existing worker nodes.
- Copy the following file to `/etc/kubernetes` on the NAS: `pki/ca.crt`.
- Make sure you have a working `~/.kube/config`
- Get `secrets.bootstrapToken` from `infrastructure/talos/talsecret.yaml` and use in second command below
- Run a few commands:
  - `sudo kubectl config --kubeconfig=/etc/kubernetes/bootstrap-kubeconfig set-cluster metal --server='https://192.168.20.20:6443' --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true`
  - `sudo kubectl config --kubeconfig=/etc/kubernetes/bootstrap-kubeconfig set-credentials tls-bootstrap-token-user --token=<token>`
  - `sudo kubectl config --kubeconfig=/etc/kubernetes/bootstrap-kubeconfig set-context tls-bootstrap-token-user@metal --user=tls-bootstrap-token-user --cluster=metal`
  - `sudo kubectl config --kubeconfig=/etc/kubernetes/bootstrap-kubeconfig use-context tls-bootstrap-token-user@metal`
- Edit the following values in `/etc/containerd/config.yaml`

```
enable_unprivileged_icmp = true
enable_unprivileged_ports = true
disable_apparmor = true
```

- Edit `/etc/systemd/system/kubelet.service`:

```
[Service]
Restart=always
ExecStart=/usr/bin/kubelet --kubeconfig=/etc/kubernetes/kubeconfig --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubeconfig --config=/etc/kubernetes/kubelet.yaml --cgroup-driver=systemd
[Install]
WantedBy=multi-user.target
```

- Create `/etc/kubernetes/kubelet.yaml` with the following content:

```
---
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 0s
    cacheUnauthorizedTTL: 0s
cgroupDriver: systemd
clusterDNS:
- 10.96.0.10
clusterDomain: cluster.local
containerRuntimeEndpoint: ""
cpuManagerReconcilePeriod: 0s
evictionPressureTransitionPeriod: 0s
fileCheckFrequency: 0s
healthzBindAddress: 127.0.0.1
healthzPort: 10248
httpCheckFrequency: 0s
imageMinimumGCAge: 0s
kind: KubeletConfiguration
logging:
  flushFrequency: 0
  options:
    json:
      infoBufferSize: "0"
  verbosity: 0
memorySwap: {}
nodeStatusReportFrequency: 0s
nodeStatusUpdateFrequency: 0s
resolvConf: /run/systemd/resolve/resolv.conf
rotateCertificates: true
runtimeRequestTimeout: 0s
serverTLSBootstrap: true
shutdownGracePeriod: 0s
shutdownGracePeriodCriticalPods: 0s
staticPodPath: /etc/kubernetes/manifests
streamingConnectionIdleTimeout: 0s
syncFrequency: 0s
volumeStatsAggPeriod: 0s
```

- `systemctl daemon-reload`
- `systemctl restart kubelet.service containerd.service`
