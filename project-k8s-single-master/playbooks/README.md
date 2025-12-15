# Playbooks Directory Structure

## 📁 Directory Organization

```
playbooks/
├── site.yml                    # Main deployment playbook
├── 01-setup/                  # Cluster setup playbooks
│   ├── site-setup.yml         # Setup orchestration
│   ├── 01-common.yaml         # Common setup for all nodes
│   ├── 02-master.yaml         # Master node setup
│   └── 03-worker.yaml         # Worker nodes setup
├── 02-maintenance/             # Maintenance operations
│   └── 01-k8s-reset-node.yml  # Reset cluster nodes
├── 03-backup/                  # Backup and restore
│   ├── 01-etcd-backup.yml     # etcd backup
│   ├── 02-setup-cron.yml      # Setup backup cron job
│   ├── 03-remove-cron.yml     # Remove backup cron job
│   └── inventory              # Backup-specific inventory
└── join-command.txt           # Worker join command
```

## 🚀 Usage Examples

### Full Cluster Setup
```bash
# Deploy complete cluster
ansible-playbook -i inventory playbooks/site.yml

# Or use setup-specific playbook
ansible-playbook -i inventory playbooks/01-setup/site-setup.yml
```

### Individual Components
```bash
# Setup common components only
ansible-playbook -i inventory playbooks/01-setup/01-common.yaml

# Setup master only
ansible-playbook -i inventory playbooks/01-setup/02-master.yaml

# Setup workers only
ansible-playbook -i inventory playbooks/01-setup/03-worker.yaml
```

### Backup Operations
```bash
# Manual backup
ansible-playbook -i inventory playbooks/03-backup/01-etcd-backup.yml

# Setup automated backup
ansible-playbook playbooks/03-backup/02-setup-cron.yml

# Remove automated backup
ansible-playbook playbooks/03-backup/03-remove-cron.yml
```

### Maintenance
```bash
# Reset all nodes
ansible-playbook -i inventory playbooks/02-maintenance/01-k8s-reset-node.yml
```

## 📋 Playbook Categories

| Category | Purpose | Files |
|----------|---------|-------|
| **01-Setup** | Initial cluster deployment | `01-setup/` |
| **02-Maintenance** | Cluster maintenance tasks | `02-maintenance/` |
| **03-Backup** | Data backup and restore | `03-backup/` |