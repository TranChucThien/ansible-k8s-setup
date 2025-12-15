# Issue: Secure Credential Management

## Problem
Storing passwords in plain text in inventory files is insecure.

## Solutions

### 1. Use Ansible Vault (Recommended)
```bash
# Create encrypted vault file
ansible-vault create vault.yml

# Add passwords to vault.yml:
vault_ssh_password: "your_password"
vault_become_password: "your_password"

# Update inventory to use vault variables:
ansible_ssh_pass: "{{ vault_ssh_password }}"
ansible_become_pass: "{{ vault_become_password }}"

# Run with vault password
ansible-playbook -i inventory playbooks/site.yml --ask-vault-pass
```

### 2. Use SSH Keys (Best Practice)
```bash
# Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_key

# Copy to target hosts
ssh-copy-id -i ~/.ssh/ansible_key.pub user@host

# Update inventory:
ansible_ssh_private_key_file=~/.ssh/ansible_key
# Remove ansible_ssh_pass lines
```

### 3. Environment Variables
```bash
# Set environment variables
export ANSIBLE_SSH_PASS="your_password"
export ANSIBLE_BECOME_PASS="your_password"

# Update inventory:
ansible_ssh_pass: "{{ lookup('env', 'ANSIBLE_SSH_PASS') }}"
ansible_become_pass: "{{ lookup('env', 'ANSIBLE_BECOME_PASS') }}"
```

### 4. External Credential Store
```bash
# Use external tools like:
# - HashiCorp Vault
# - AWS Secrets Manager
# - Azure Key Vault
# - CyberArk
```

## Git Security
```bash
# Add to .gitignore:
inventory
inventory-*
!inventory.example
*.pem
*.key
.vault_pass
```

## Prevention
- Never commit real credentials to git
- Use example files with placeholder values
- Implement proper secret management from day one