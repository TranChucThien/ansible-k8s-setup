# Issue: SSH Connection Failed

## Symptoms
```text
UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh"}
```

## Cause
- Wrong SSH credentials
- Network connectivity issues
- SSH service not running
- Firewall blocking port 22

## Solution

### For Password Authentication
```bash
# Test SSH manually
ssh user@host

# Check inventory credentials
[masters:vars]
ansible_user=ubuntu
ansible_ssh_pass=password
ansible_become_pass=password
```

### For Key Authentication
```bash
# Check key permissions
chmod 600 ansible-key.pem

# Test key
ssh -i ansible-key.pem ubuntu@host

# Update inventory
ansible_ssh_private_key_file=ansible-key.pem
```

### Network Issues
```bash
# Test connectivity
ping host_ip

# Check SSH service
systemctl status ssh
```

## Prevention
- Always test SSH manually before running playbooks
- Use `ansible all -i inventory -m ping` to verify connectivity