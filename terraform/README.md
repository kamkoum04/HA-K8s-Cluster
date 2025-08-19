# Terraform Infrastructure Documentation

🏗️ **Infrastructure as Code for HA Kubernetes Cluster**

This module provisions cloud infrastructure on DigitalOcean for a High Availability Kubernetes cluster.

## 📋 Overview

Creates a complete infrastructure setup with:
- **1 Load Balancer** (NGINX proxy for API server)
- **3 Master nodes** (HA control plane)
- **2 Worker nodes** (workload execution)
- **SSH key management**
- **Networking & security groups**

## 📁 File Structure

```
terraform/
├── 📜 Configuration Files
│   ├── main.tf                    # Main infrastructure definition
│   ├── variables.tf               # Input variables & defaults
│   ├── outputs.tf                 # Output values (IPs)
│   ├── providers.tf               # Provider configuration
│   └── ssh_key.tf                 # SSH key resource
│
├── 🔧 Configuration
│   ├── terraform.auto.tfvars      # Your actual values (gitignored)
│   └── terraform.auto.tfvars.example # Template file
│
├── 📁 modules/droplet/            # Reusable droplet module
│   ├── main.tf                    # Droplet resource definition
│   ├── variables.tf               # Module input variables
│   ├── outputs.tf                 # Module outputs
│   └── providers.tf               # Module provider requirements
│
└── 📚 Documentation
    ├── README.md                  # This file
    └── MULTI_USER_SSH.md          # SSH access documentation
```

## 🚀 Quick Usage

### 1. Setup Configuration
```bash
# Copy the example file
cp terraform.auto.tfvars.example terraform.auto.tfvars

# Edit with your values
nano terraform.auto.tfvars
```

### 2. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply changes
terraform apply
```

### 3. Get Outputs
```bash
# Show all outputs
terraform output

# Get specific IP
terraform output lb_ip
terraform output master_ips
terraform output worker_ips
```

## 📄 File Details

### `main.tf`
**Purpose:** Main infrastructure definition using modules
**What it does:**
- Creates load balancer droplet (1x s-1vcpu-1gb)
- Creates master nodes (3x s-2vcpu-2gb) 
- Creates worker nodes (2x s-2vcpu-2gb)
- Uses Ubuntu 24.10 for all nodes
- Applies consistent tagging

### `variables.tf`
**Purpose:** Define input variables with defaults
**Variables:**
- `do_token` - DigitalOcean API token (required)
- `ssh_key_name` - SSH key name (required)
- `ssh_pub_key` - SSH public key content (required)
- `region` - Deployment region (default: fra1)
- `master_count` - Number of masters (default: 3)
- `worker_count` - Number of workers (default: 2)

### `providers.tf`
**Purpose:** Configure Terraform providers
**Features:**
- DigitalOcean provider v2.0+
- Remote backend configuration (Terraform Cloud)
- Provider version constraints

### `outputs.tf`
**Purpose:** Export important values for use by Ansible
**Outputs:**
- `lb_ip` - Load balancer public IP
- `master_ips` - Array of master node IPs
- `worker_ips` - Array of worker node IPs

### `ssh_key.tf`
**Purpose:** Manage SSH key resource
**What it does:**
- Creates/manages SSH key in DigitalOcean
- Used by all droplets for access

### `terraform.auto.tfvars`
**Purpose:** Your actual configuration values (gitignored for security)
**Required values:**
```hcl
do_token     = "dop_v1_your_token_here"
ssh_key_name = "your-key-name"
ssh_pub_key  = "ssh-rsa AAAAB3... your-public-key"
```

## 🏗️ Module: droplet

Reusable module for creating DigitalOcean droplets.

### Module Files

#### `modules/droplet/main.tf`
**Purpose:** Droplet resource definition
**What it does:**
- Creates specified number of droplets
- Uses count parameter for multiple instances
- Applies consistent naming with index

#### `modules/droplet/variables.tf`
**Purpose:** Module input parameters
**Variables:**
- `name_prefix` - Prefix for droplet names
- `region` - DigitalOcean region
- `size` - Droplet size (CPU/RAM)
- `image` - Operating system image
- `ssh_keys` - SSH key IDs for access
- `tags` - Tags for organization
- `droplet_count` - Number of droplets to create
- `user_data` - Cloud-init script (optional)

#### `modules/droplet/outputs.tf`
**Purpose:** Export droplet information
**Outputs:**
- `droplet_ips` - Array of public IP addresses

#### `modules/droplet/providers.tf`
**Purpose:** Module provider requirements
**Requirements:**
- DigitalOcean provider v2.0+
- Must match root module provider version

## 💰 Cost Estimation

| Resource | Count | Size | Monthly Cost* |
|----------|-------|------|---------------|
| Load Balancer | 1 | s-1vcpu-1gb | $6/month |
| Masters | 3 | s-2vcpu-2gb | $18/month each |
| Workers | 2 | s-2vcpu-2gb | $18/month each |
| **Total** | **6** | | **~$96/month** |

*Prices as of 2024, may vary by region

## 🔧 Customization

### Change Droplet Sizes
```hcl
# In main.tf, modify size parameters:
module "masters" {
  size = "s-4vcpu-8gb"  # Larger masters
}

module "workers" {
  size = "s-2vcpu-4gb"  # More worker RAM
}
```

### Change Region
```hcl
# In terraform.auto.tfvars:
region = "nyc1"  # New York instead of Frankfurt
```

### Scale Cluster
```hcl
# In terraform.auto.tfvars:
master_count = 5  # More masters
worker_count = 4  # More workers
```

## 🔍 Verification

### Check Resources
```bash
# List all droplets
doctl compute droplet list

# Check SSH key
doctl compute ssh-key list

# Verify networking
ping $(terraform output -raw lb_ip)
```

### Terraform State
```bash
# Show resources in state
terraform state list

# Show specific resource
terraform state show module.masters.digitalocean_droplet.this[0]

# Refresh state from cloud
terraform refresh
```

## 🔄 Lifecycle Management

### Updates
```bash
# Update configuration
nano main.tf

# Plan changes
terraform plan

# Apply updates
terraform apply
```

### Scaling
```bash
# Increase worker count
echo 'worker_count = 4' >> terraform.auto.tfvars

# Apply changes
terraform apply
```

### Cleanup
```bash
# Destroy all resources
terraform destroy

# Confirm destruction
# Type 'yes' when prompted
```

## 🛠️ Troubleshooting

### Common Issues

**Authentication failed:**
```bash
# Check your token
doctl auth init --access-token $DO_TOKEN
doctl account get
```

**SSH key not found:**
```bash
# List available keys
doctl compute ssh-key list

# Upload new key
doctl compute ssh-key create my-key --public-key-file ~/.ssh/id_rsa.pub
```

**Region not available:**
```bash
# List available regions
doctl compute region list

# List available sizes per region
doctl compute size list
```

**Resource limits:**
```bash
# Check account limits
doctl account get

# Contact support if needed
```

### Debug Commands
```bash
# Enable detailed logging
export TF_LOG=DEBUG
terraform apply

# Validate configuration
terraform validate

# Format configuration
terraform fmt
```

## 🔗 Related Documentation

- [DigitalOcean Terraform Provider](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs)
- [Terraform Module Development](https://developer.hashicorp.com/terraform/language/modules/develop)
- [DigitalOcean API Documentation](https://docs.digitalocean.com/reference/api/)

---

**Next:** [Ansible Configuration →](../ansible/README.md)
