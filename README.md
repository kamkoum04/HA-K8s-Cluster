# HA Kubernetes Cluster Deployment Guide

> **Automated High Availability Kubernetes Cluster on DigitalOcean using Terraform + Ansible**

This project provides a streamlined, learner-friendly approach to deploy a production-ready HA Kubernetes cluster with just a few commands.

## 🏗️ Architecture

- **3 Master Nodes** (Control Plane HA)
- **2 Worker Nodes** (Workload Execution)
- **1 Load Balancer** (HAProxy for API Server HA)
- **Calico CNI** (Pod Networking)
- **containerd** (Container Runtime)

## 📋 Prerequisites

- DigitalOcean account with API token
- Local machine with:
  - Terraform installed
  - Ansible installed
  - `jq` installed
  - SSH key pair generated

## 🚀 Quick Start

### 1. Clone and Configure
```bash
git clone <your-repo>
cd playsoftintern
```

### 2. Setup Terraform Variables
Edit `terrform/terraform.auto.tfvars`:
```hcl
do_token = "your_digitalocean_token"
ssh_key_name = "your_ssh_key_name"
```

### 3. Deploy Everything (Automated)
```bash
# Option 1: Full automation (recommended for beginners)
./full-deploy.sh

# Option 2: Step by step
./script.sh          # Provision infrastructure + update configs
./deploy-k8s.sh      # Deploy Kubernetes cluster
```

### 4. Access Your Cluster
```bash
# SSH to any master node
ssh ansible@<master-ip>

# Check cluster status
kubectl get nodes
kubectl cluster-info
```

## 📁 Project Structure

```
playsoftintern/
├── script.sh              # Infrastructure provisioning + config updates
├── deploy-k8s.sh          # Kubernetes deployment via Ansible
├── full-deploy.sh         # Complete automation (script.sh + deploy-k8s.sh)
├── setup-ssh.sh           # Optional SSH setup automation
├── terrform/              # Infrastructure as Code
│   ├── main.tf            # Main infrastructure definition
│   ├── variables.tf       # Input variables
│   ├── outputs.tf         # Output values (IPs)
│   ├── terraform.auto.tfvars  # Your configuration
│   └── modules/droplet/   # DigitalOcean droplet module
└── ha-k8s-ansible/        # Kubernetes deployment automation
    ├── deploy.yml         # Main Ansible playbook
    ├── inventory.ini      # Dynamically updated by script.sh
    ├── vars.yml           # Cluster configuration
    └── playbooks/         # Step-by-step deployment tasks
```

## 🛠️ Deployment Scripts Explained

### `script.sh` - Infrastructure & Configuration
**What it does:**
- Runs `terraform init` and `terraform apply`
- Extracts IPs from Terraform outputs
- Updates Ansible `inventory.ini` with actual server IPs
- Updates `vars.yml` with load balancer and master IPs
- Configures SSH access and ansible user on all nodes

**Why this approach:**
- ✅ Simple and focused
- ✅ Separates infrastructure from application deployment
- ✅ Dynamic IP handling (no manual configuration)
- ✅ Learner-friendly with clear steps

### `deploy-k8s.sh` - Kubernetes Deployment
**What it does:**
- Validates configuration files exist
- Tests connectivity to all nodes
- Runs the main Ansible playbook (`deploy.yml`)
- Provides clear success/failure feedback

**Safety features:**
- ✅ Pre-flight checks before deployment
- ✅ Connectivity testing
- ✅ Clear error messages
- ✅ Post-deployment guidance

### `full-deploy.sh` - Complete Automation
**What it does:**
- Runs `script.sh` (infrastructure)
- Waits for infrastructure to be ready
- Runs `deploy-k8s.sh` (Kubernetes)
- End-to-end automation

## 🎯 Design Philosophy

### Why This Approach?

1. **Learner-Friendly**: Each script has a single, clear purpose
2. **Separation of Concerns**: Infrastructure ≠ Application deployment
3. **Flexibility**: Can run steps individually or all together
4. **Error Handling**: Clear feedback at each step
5. **No Manual Configuration**: Fully automated IP updates

### What Makes It Different?

- **Dynamic Configuration**: No hardcoded IPs anywhere
- **Minimal Complexity**: Only automates what should be automated
- **Clear Workflow**: Infrastructure → Configuration → Deployment
- **Educational Value**: Each step is visible and understandable

## 🔧 Configuration Files

### `vars.yml` - Cluster Configuration
```yaml
kubernetes_version: "1.31"
containerd_version: "1.7.22" 
calico_version: "3.28.2"
cluster_name: "ha-k8s-cluster"
lb_ip: "auto-updated-by-script"
master_ips:
  - "auto-updated-by-script"
  - "auto-updated-by-script" 
  - "auto-updated-by-script"
```

### `inventory.ini` - Ansible Inventory
```ini
[lb]
lb1 ansible_host=auto-updated-by-script

[masters]
master1 ansible_host=auto-updated-by-script
master2 ansible_host=auto-updated-by-script
master3 ansible_host=auto-updated-by-script

[workers]
worker1 ansible_host=auto-updated-by-script
worker2 ansible_host=auto-updated-by-script

[all:vars]
ansible_user=ansible
```

## 🎓 Learning Path

### For Beginners
1. Start with `./full-deploy.sh` - see the complete process
2. Explore the generated `inventory.ini` and `vars.yml` files
3. SSH into nodes and explore the cluster

### For Advanced Users
1. Run scripts individually: `./script.sh` then `./deploy-k8s.sh`
2. Customize `vars.yml` for different configurations
3. Modify Ansible playbooks in `playbooks/` directory

## 🔍 Troubleshooting

### Common Issues

**1. Terraform fails**
```bash
cd terrform/
terraform plan  # Check for configuration issues
```

**2. SSH connectivity issues**
```bash
./setup-ssh.sh  # Run SSH setup if needed
```

**3. Ansible deployment fails**
```bash
cd ha-k8s-ansible/
ansible all -i inventory.ini -m ping  # Test connectivity
```

### Debugging Tips
- Check Terraform outputs: `cd terrform && terraform output`
- Verify SSH access: `ssh ansible@<node-ip>`
- Review Ansible logs for specific error messages

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request


## 🙏 Acknowledgments

- Built for learning and production use
- Focuses on simplicity and reliability
- Community-driven improvements welcome

---

**⭐ If this helped you, please star the repository!**

> **Ready to deploy?** Just run `./full-deploy.sh` and have your HA Kubernetes cluster ready in minutes!
