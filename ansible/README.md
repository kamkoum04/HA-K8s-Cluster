# Ansible Configuration

⚙️ **Deploys Kubernetes automatically**

## What It Does
- Installs Kubernetes on all servers
- Configures 3 master nodes for HA
- Sets up 2 worker nodes
- Installs networking and tools

## Files
- `deploy.yml` - Main automation script
- `inventory.ini` - Server list (auto-created)
- `vars.yml` - Settings
- `playbooks/` - Step-by-step tasks

## Usage

**Deploy everything:**
```bash
ansible-playbook -i inventory.ini deploy.yml
```

**Test connections:**
```bash
ansible all -i inventory.ini -m ping
```

**Check cluster:**
```bash
ansible master1 -i inventory.ini -m shell -a "kubectl get nodes" --become-user=ansible
```

## Troubleshooting

**Can't connect:**
```bash
ansible all -i inventory.ini -m ping -vvv
```

**Deployment fails:**
```bash
ansible-playbook -i inventory.ini deploy.yml -vvv
```
