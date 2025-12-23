# Troubleshooting Guide

Quick reference for common Kubernetes deployment issues and solutions.

## 📁 Structure

```text
troubleshooting/
├── common/           # Issues affecting all nodes
├── master/           # Master node specific issues
├── worker/           # Worker node specific issues
├── network/          # Network and CNI issues
└── README.md         # This guide
```

## 🚨 Quick Diagnostics

```bash
# Check all nodes status
kubectl get nodes -o wide

# Check system pods
kubectl get pods -A

# Check logs
kubectl logs -n kube-system <pod-name>

# Check node resources
kubectl describe node <node-name>
```

## 📋 Issue Categories

### [Common Issues](common/)
- SSH connection problems
- Ansible execution errors
- Package installation failures
- System requirements

### [Master Issues](master/)
- Cluster initialization failures
- API server problems
- etcd issues
- Control plane components

### [Worker Issues](worker/)
- Node join failures
- Kubelet problems
- Container runtime issues
- Pod scheduling problems

### [Network Issues](network/)
- CNI plugin failures
- Pod networking problems
- Service connectivity
- DNS resolution

## 🔍 Diagnostic Commands

```bash
# Node diagnostics
systemctl status kubelet
journalctl -u kubelet -f

# Network diagnostics
kubectl get pods -n calico-system
kubectl describe node <node> | grep -A5 Conditions

# Cluster diagnostics
kubectl cluster-info
kubectl get events --sort-by='.lastTimestamp'
```

## 📝 Adding New Issues

Create new files using this template:

```markdown
# Issue: [Brief Description]

## Symptoms
- What you see/error messages

## Cause
- Why this happens

## Solution
- Step-by-step fix

## Prevention
- How to avoid this issue
```

## 🔗 External Resources

- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)
- [Calico Troubleshooting](https://docs.tigera.io/calico/latest/operations/troubleshoot/)