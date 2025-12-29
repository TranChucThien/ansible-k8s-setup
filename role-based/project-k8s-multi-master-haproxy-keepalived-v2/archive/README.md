# Archived Playbooks

This directory contains the original playbooks before refactoring to roles.

## Original Structure

The original playbooks were:
- `00-ha.yml` - HAProxy + Keepalived setup
- `01-common.yaml` - Common node setup
- `02-cluster-init-master.yaml` - Initialize first master
- `03-join-master.yaml` - Join additional masters
- `03-join-worker.yaml` - Join worker nodes
- `site.yml` - Main deployment playbook

## Migration to Roles

These playbooks have been refactored into the following modular roles:
- `common` - System setup + etcdctl (replaces parts of `01-common.yaml`)
- `containerd` - Container runtime (replaces parts of `01-common.yaml`)
- `kubernetes/install` - Install k8s packages (replaces parts of `01-common.yaml`)
- `kubernetes/master` - Initialize master (replaces `02-cluster-init-master.yaml`)
- `kubernetes/join` - Generate join commands (replaces parts of `03-join-master.yaml`)
- `kubernetes/worker` - Join workers/masters (replaces `03-join-master.yaml` and `03-join-worker.yaml`)
- `kubernetes/reset` - Cluster cleanup
- `network/calico` - CNI plugin (replaces parts of `02-cluster-init-master.yaml`)
- `etcd/backup` - ETCD backup operations
- `haproxy_keepalived` - HAProxy + Keepalived HA (replaces `00-ha.yml`)

## Usage

These archived playbooks are kept for reference and can still be used if needed:

```bash
# Using archived playbooks
ansible-playbook -i inventories/lab/hosts.ini archive/playbooks/site.yml
```

However, it's recommended to use the new role-based playbooks in the `playbooks/` directory.