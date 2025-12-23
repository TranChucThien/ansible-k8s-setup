# Issue: Worker Node Not Ready

## Symptoms
```bash
kubectl get nodes
NAME           STATUS     ROLES    AGE   VERSION
k8s-master-1   Ready      master   10m   v1.33.x
k8s-worker-1   NotReady   <none>   5m    v1.33.x
```

## Cause
- CNI plugin not installed/working
- Kubelet service issues
- Network connectivity problems

## Solution

### Check CNI Status
```bash
# Check Calico pods
kubectl get pods -n calico-system

# Check node conditions
kubectl describe node k8s-worker-1
```

### Fix Kubelet Issues
```bash
# On worker node
sudo systemctl status kubelet
sudo journalctl -u kubelet -f

# Restart kubelet
sudo systemctl restart kubelet
```

### Reinstall CNI
```bash
# On master node
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml
```

### Re-join Worker
```bash
# Reset worker
ansible-playbook -i inventory playbooks/clean-worker.yml --limit workers

# Re-join
ansible-playbook -i inventory playbooks/03-worker.yaml
```

## Prevention
- Wait for master to be fully ready before joining workers
- Ensure network connectivity between all nodes