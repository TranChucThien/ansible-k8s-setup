# Issue: Pods Stuck in Pending State

## Symptoms
```bash
kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
my-app-xxx               0/1     Pending   0          5m
```

## Cause
- No available nodes
- Resource constraints
- Node selector/affinity issues
- Taints on nodes

## Solution

### Check Node Resources
```bash
# Check node capacity
kubectl describe nodes

# Check resource usage
kubectl top nodes
kubectl top pods
```

### Check Scheduling Issues
```bash
# Describe pending pod
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### Remove Taints (if needed)
```bash
# List taints
kubectl describe node <node-name> | grep Taints

# Remove taint from master (for single-node testing)
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

### Check CNI Status
```bash
# Verify Calico is running
kubectl get pods -n calico-system

# Check node network status
kubectl get nodes -o wide
```

## Prevention
- Monitor resource usage regularly
- Ensure adequate node capacity
- Verify CNI plugin is healthy