# Remote Cluster (No Sudo) Helm Chart

This Helm chart deploys k0rdent remote clusters running as root without requiring sudo commands during deployment.

## Overview

This chart is specifically designed for environments where:
- You have SSH access to remote machines as root
- You want to avoid using sudo commands during deployment
- You need to deploy k0s clusters on existing infrastructure
- The k0s service runs as root with full system privileges

## Key Features

- **No sudo required**: All operations run directly as root
- **System-wide installation**: k0s binary and configuration stored in standard system directories
- **Systemd system services**: Uses standard systemd system services
- **Configurable SSH access**: Flexible SSH configuration for various environments
- **Full k0s functionality**: Complete k0s cluster capabilities with root privileges

## Prerequisites

### On Remote Machines

1. **SSH Access**: SSH access enabled for root user
2. **Root Access**: Direct root access via SSH (no sudo needed)
3. **Systemd Services**: Standard systemd system service support
4. **Network Access**: Internet access for downloading k0s binary and container images
5. **System Directories**: Standard system directories (/usr/local/bin, /etc/k0s, /var/lib/k0s)

### On Management Cluster

1. **k0rdent Enterprise**: k0rdent management cluster installed and running
2. **SSH Key**: Private SSH key accessible to the k0rdent system
3. **Network Connectivity**: Network access from management cluster to remote machines

## Quick Start

### 1. Prepare Remote Machines

Enable SSH access for root on each remote machine:

```bash
# Enable root SSH access (if not already enabled)
# Edit /etc/ssh/sshd_config
PermitRootLogin yes

# Restart SSH service
systemctl restart ssh

# Set up SSH key for root user
mkdir -p /root/.ssh
chmod 700 /root/.ssh
# Copy your SSH public key to /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```

### 2. Create SSH Secret

```bash
# Create SSH key secret
kubectl create secret generic remote-ssh-key \
  --from-file=value=/path/to/private/ssh/key \
  -n kcm-system
```

### 3. Create Credential Object

```yaml
apiVersion: k0rdent.mirantis.com/v1beta1
kind: Credential
metadata:
  name: remote-nosudo-cred
  namespace: kcm-system
spec:
  identityRef:
    apiVersion: v1
    kind: Secret
    name: remote-ssh-key
    namespace: kcm-system
```

### 4. Deploy the Cluster Template

```yaml
apiVersion: k0rdent.mirantis.com/v1beta1
kind: ClusterDeployment
metadata:
  name: my-remote-nosudo-cluster
  namespace: kcm-system
spec:
  template: remote-cluster-nosudo-1-0-0
  credential: remote-nosudo-cred
  config:
    machines:
      - address: "192.168.1.100"
        user: "root"
        port: 22
        role: "worker"
      - address: "192.168.1.101"
        user: "root"
        port: 22
        role: "worker"
    k0smotron:
      service:
        type: LoadBalancer
```

## Configuration

### Core Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `controlPlaneNumber` | Number of control plane nodes | `1` |
| `workersNumber` | Number of worker nodes | `1` |
| `machines` | Array of remote machine configurations | `[]` |

### Machine Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `machines[].address` | IP address or hostname | Required |
| `machines[].user` | SSH username | `"root"` |
| `machines[].port` | SSH port | `22` |
| `machines[].sshKeyPath` | Path to SSH private key | `""` |
| `machines[].role` | Machine role (worker/control-plane) | `"worker"` |

### Root-Based Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `machineConfig.user.name` | Username for k0s service | `"root"` |
| `machineConfig.user.home` | Home directory | `"/root"` |
| `machineConfig.paths.k0sBinary` | k0s binary path | `"/usr/local/bin/k0s"` |
| `machineConfig.paths.k0sConfig` | k0s config directory | `"/etc/k0s"` |
| `machineConfig.paths.systemdUnit` | Systemd service file path | `"/etc/systemd/system/k0s.service"` |

## Advanced Configuration

### Custom k0s Configuration

```yaml
k0s:
  version: v1.31.5+k0s.0
  config:
    spec:
      api:
        extraArgs:
          anonymous-auth: "true"
      network:
        podCIDR: "10.243.0.0/16"
        serviceCIDR: "10.95.0.0/16"
```

### Service Configuration

```yaml
k0smotron:
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: nlb
```

## Limitations

1. **Root Access Required**: Requires SSH access as root user
2. **Security Considerations**: Running as root requires careful security planning
3. **SSH Configuration**: May require enabling root SSH access on target machines

## Troubleshooting

### Common Issues

1. **SSH Root Access Denied**
   ```bash
   # Enable root SSH access in /etc/ssh/sshd_config
   PermitRootLogin yes
   systemctl restart ssh
   ```

2. **Permission Issues**
   ```bash
   # Verify root SSH key permissions
   chmod 600 /root/.ssh/authorized_keys
   chmod 700 /root/.ssh
   ```

3. **k0s Binary Download Fails**
   ```bash
   # Check internet access and download manually
   curl -sSLf https://get.k0s.sh | sh
   ```

### Debugging

Check the k0s service status:
```bash
# On the remote machine as root
systemctl status k0s
journalctl -u k0s -f
```

## Contributing

This chart is part of the k0rdent-oot project. Please refer to the main project documentation for contribution guidelines.

## License

This chart is licensed under the same license as the k0rdent-oot project.
