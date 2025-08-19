# HA Kubernetes Cluster - Automated Deployment

🚀 **Automated High Availability Kubernetes cluster on DigitalOcean**

## What This Does

Creates a production-ready Kubernetes cluster with:
- **3 Master nodes** (High Availability)
- **2 Worker nodes** 
- **1 Load balancer** (NGINX)
- **Automated setup** with Terraform + Ansible

## Quick Start

### 1. Setup
```bash
# Copy configuration template
cp terraform/terraform.auto.tfvars.example terraform/terraform.auto.tfvars

# Edit with your DigitalOcean token and SSH key
nano terraform/terraform.auto.tfvars
```

### 2. Deploy Everything
```bash
# One command deployment (recommended)
./full-deploy.sh

# OR step by step:
./script.sh        # Create infrastructure
./deploy-k8s.sh    # Deploy Kubernetes
```

### 3. Access Your Cluster
```bash
# Get kubeconfig
ansible master1 -i ansible/inventory.ini -m fetch \
  -a "src=/home/ansible/.kube/config dest=./kubeconfig flat=yes" \
  --become-user=ansible

# Use cluster
export KUBECONFIG=./kubeconfig
kubectl get nodes
```

## What You Get

- **Kubernetes 1.33.1** with containerd runtime
- **Calico networking** for pods
- **Helm package manager**
- **Metrics server** for monitoring
- **NGINX ingress controller**
- **RBAC user management** system

## File Structure

```
├── script.sh              # Infrastructure setup
├── deploy-k8s.sh          # Kubernetes deployment  
├── full-deploy.sh         # Complete automation
├── terraform/             # Infrastructure code
├── ansible/               # Configuration management
└── kubernetes/rbac/       # User access control
```

## Common Commands

```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Scale workers (edit terraform/variables.tf then):
terraform apply
./deploy-k8s.sh

# Destroy everything
terraform destroy
```

