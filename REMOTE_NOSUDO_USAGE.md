# Remote Cluster Deployment Without Sudo - Usage Guide

This guide explains how to use the custom `remote-cluster-nosudo` chart to deploy k0rdent clusters on remote machines without requiring sudo access.

## Overview

The `remote-cluster-nosudo` chart is specifically designed for environments where:
- You have SSH access to remote machines
- The SSH user does not have sudo privileges  
- You need to deploy k0s clusters on existing infrastructure
- The k0s service runs as a regular user (not root)

## Key Differences from Standard k0rdent Remote Deployment

| Aspect | Standard k0rdent | remote-cluster-nosudo |
|--------|------------------|----------------------|
| **Sudo Requirement** | Required on remote machines | **Not required** |
| **Installation Location** | System directories (/usr/local/bin, /etc) | User directories (/home/user/bin, /home/user/.k0s) |
| **Service Management** | systemd system services | systemd user services |
| **User Privileges** | Runs as root | Runs as regular user |
| **Setup Complexity** | Simple (if sudo available) | Slightly more complex setup |

## Architecture

```
Management Cluster (k0rdent)
    │
    ├── k0smotron (Hosted Control Plane)
    │   └── Kubernetes API Server (LoadBalancer/NodePort)
    │
    └── SSH Connections to Remote Machines
        ├── Machine 1 (SSH User: k0s, No Sudo)
        │   ├── /home/k0s/bin/k0s (binary)
        │   ├── /home/k0s/.k0s/ (config)
        │   └── systemd --user k0s.service
        │
        └── Machine 2 (SSH User: k0s, No Sudo)
            ├── /home/k0s/bin/k0s (binary)
            ├── /home/k0s/.k0s/ (config)
            └── systemd --user k0s.service
```

## Prerequisites

### Management Cluster
1. k0rdent Enterprise installed and running
2. Network connectivity to remote machines
3. SSH private key for remote access

### Remote Machines (Each Worker Node)
1. **Linux OS** compatible with k0s requirements
2. **SSH access enabled** for a regular user (default: `k0s`)
3. **Systemd with user services** support
4. **Internet access** for downloading k0s binary
5. **User setup** (one-time, may require sudo initially):

```bash
# On each remote machine (requires sudo for initial setup only)
sudo useradd -m -s /bin/bash k0s
sudo loginctl enable-linger k0s  # Enable systemd user services for k0s
sudo -u k0s mkdir -p /home/k0s/.ssh
sudo -u k0s chmod 700 /home/k0s/.ssh
# Copy SSH public key to /home/k0s/.ssh/authorized_keys
```

## Step-by-Step Deployment

### 1. Prepare SSH Access

Create SSH key secret on management cluster:

```bash
# Create SSH key secret
kubectl create secret generic remote-ssh-key-nosudo \
  --from-file=value=$HOME/.ssh/id_rsa \
  -n kcm-system \
  --dry-run=client -o yaml | kubectl apply -f -

# Label the secret
kubectl label secret remote-ssh-key-nosudo \
  k0rdent.mirantis.com/component=kcm -n kcm-system
```

### 2. Create Credential Object

```bash
cat <<EOF | kubectl apply -f -
apiVersion: k0rdent.mirantis.com/v1beta1
kind: Credential
metadata:
  name: remote-nosudo-cred
  namespace: kcm-system
spec:
  identityRef:
    apiVersion: v1
    kind: Secret
    name: remote-ssh-key-nosudo
    namespace: kcm-system
EOF
```

### 3. Install Provider Package

```bash
# Install the provider package to make template available
helm install remote-nosudo-provider \
  ./charts/remote-nosudo-pp \
  -n kcm-system
```

### 4. Verify Template Availability

```bash
kubectl get clustertemplate -n kcm-system | grep remote-cluster-nosudo
# Should show: remote-cluster-nosudo-1-0-0
```

### 5. Deploy Cluster

```bash
cat <<EOF | kubectl apply -f -
apiVersion: k0rdent.mirantis.com/v1beta1
kind: ClusterDeployment
metadata:
  name: my-remote-nosudo-cluster
  namespace: kcm-system
spec:
  template: remote-cluster-nosudo-1-0-0
  credential: remote-nosudo-cred
  config:
    controlPlaneNumber: 1
    workersNumber: 2
    machines:
      - address: "192.168.1.100"
        user: "k0s"
        port: 22
        role: "worker"
      - address: "192.168.1.101"  
        user: "k0s"
        port: 22
        role: "worker"
    k0smotron:
      service:
        type: LoadBalancer
    machineConfig:
      user:
        name: "k0s"
        home: "/home/k0s"
      paths:
        k0sBinary: "/home/k0s/bin/k0s"
        k0sConfig: "/home/k0s/.k0s"
        systemdUnit: "/home/k0s/.config/systemd/user/k0s.service"
EOF
```

### 6. Monitor Deployment

```bash
# Watch cluster deployment status
kubectl get clusterdeployment my-remote-nosudo-cluster -n kcm-system -w

# Check cluster status
kubectl get cluster my-remote-nosudo-cluster -n kcm-system

# Monitor machines
kubectl get remotemachines -n kcm-system -l helm.toolkit.fluxcd.io/name=my-remote-nosudo-cluster
```

### 7. Obtain kubeconfig

```bash
# Get cluster kubeconfig
kubectl get secret my-remote-nosudo-cluster-kubeconfig \
  -n kcm-system \
  -o jsonpath='{.data.value}' | base64 -d > cluster-kubeconfig.yaml

# Test cluster access
KUBECONFIG=cluster-kubeconfig.yaml kubectl get nodes
```

## Configuration Options

### Machine-Specific Configuration

```yaml
machines:
  - address: "192.168.1.100"
    user: "k0s"              # SSH user (must exist on remote machine)
    port: 22                 # SSH port
    role: "worker"           # Role: worker or control-plane
    sshKeyPath: ""           # Optional: specific SSH key path
    hostKey: ""              # Optional: SSH host key for verification
```

### k0s Configuration

```yaml
k0s:
  version: v1.31.5+k0s.0     # k0s version
  downloadURL: ""            # Optional: custom download URL
  config:
    spec:
      api:
        extraArgs:
          anonymous-auth: "true"
      network:
        podCIDR: "10.243.0.0/16"
        serviceCIDR: "10.95.0.0/16"
        provider: calico
```

### Service Configuration

```yaml
k0smotron:
  service:
    type: LoadBalancer       # ClusterIP, NodePort, or LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: nlb
```

## Troubleshooting

### Common Issues

1. **SSH Connection Fails**
   ```bash
   # Test SSH connection manually
   ssh -i ~/.ssh/id_rsa k0s@192.168.1.100
   ```

2. **Systemd User Service Issues**
   ```bash
   # On remote machine as k0s user
   systemctl --user status k0s
   journalctl --user -u k0s -f
   
   # Check if lingering is enabled
   loginctl show-user k0s
   ```

3. **k0s Binary Download Fails**
   ```bash
   # On remote machine, test download manually
   curl -sSLf https://get.k0s.sh | sh -s -- --k0s-version=v1.31.5+k0s.0
   ```

4. **Permission Issues**
   ```bash
   # Check directory ownership on remote machine
   ls -la /home/k0s/
   # Should show k0s:k0s ownership
   ```

### Debugging Commands

```bash
# Check cluster events
kubectl get events -n kcm-system --sort-by='.lastTimestamp'

# Check k0smotron logs
kubectl logs -n kcm-system -l app.kubernetes.io/name=k0smotron

# Check machine status
kubectl describe remotemachine <machine-name> -n kcm-system
```

## Limitations

1. **Container Runtime**: Uses containerd in rootless mode
2. **Privileged Operations**: Cannot perform operations requiring root
3. **System Integration**: Limited integration with system services
4. **Port Restrictions**: Limited to unprivileged ports (>1024) for some services
5. **Storage**: Some storage drivers may not work in rootless mode

## Advanced Configuration

### Custom User Configuration

```yaml
machineConfig:
  user:
    name: "myuser"           # Custom username
    home: "/home/myuser"     # Custom home directory
  paths:
    k0sBinary: "/home/myuser/bin/k0s"
    k0sConfig: "/home/myuser/.k0s"
    systemdUnit: "/home/myuser/.config/systemd/user/k0s.service"
```

### Custom Commands

```yaml
machineConfig:
  preStartCommands:
    - "mkdir -p /home/k0s/bin"
    - "mkdir -p /home/k0s/.k0s"
    - "export CUSTOM_VAR=value"
  postStartCommands:
    - "systemctl --user daemon-reload"
    - "systemctl --user enable k0s"
    - "systemctl --user start k0s"
    - "echo 'k0s service started' >> /home/k0s/startup.log"
```

## Migration from Sudo-based Deployment

If you have existing sudo-based deployments and want to migrate:

1. **Backup existing cluster data**
2. **Create new deployment** with no-sudo chart  
3. **Migrate workloads** to new cluster
4. **Decommission old cluster**

Note: Direct in-place migration is not supported due to fundamental differences in service management.

## Support

For issues specific to this no-sudo deployment:

1. Check this troubleshooting guide
2. Review k0s documentation for rootless mode limitations
3. Consult k0rdent community forums
4. File issues in the k0rdent-oot repository

## Security Considerations

1. **SSH Key Management**: Secure SSH private keys properly
2. **User Isolation**: k0s user should be dedicated to cluster operations
3. **Network Security**: Restrict network access as appropriate
4. **Updates**: Regular updates to k0s and container images
5. **Monitoring**: Monitor user-space services for security events
