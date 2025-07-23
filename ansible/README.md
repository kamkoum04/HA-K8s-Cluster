# 🚀 HA Kubernetes Cluster - Complete Guide for Beginners

**Updated:** 2025-07-02 by kamkoum04  
**Purpose:** Step-by-step manual deployment with explanations for learning

## 📋 Quick Overview

This creates a **High Availability Kubernetes cluster** with:
- **1 Load Balancer** (distributes traffic)
- **3 Master nodes** (control the cluster)  
- **2 Worker nodes** (run applications)
- **Total: 6 servers working together**

## 🔧 Manual Deployment Steps (Run One by One)

## � Manual Deployment Steps (Run One by One)

### Step 0: Prerequisites Check 
```bash
# Test connectivity to all servers
ansible all -i inventory.ini -m ping

# Check if you can become root on all servers
ansible all -i inventory.ini -b -m command -a "whoami"
```
**What to expect:** All servers should respond with "pong" and show "root"

---

### 📍 STEP 1: Base System Setup

#### 1A. System Updates and Basic Tools
```bash
ansible-playbook -i inventory.ini playbooks/01-base-setup/main.yml
```

**What this does:**
- Updates Ubuntu packages to latest versions
- Installs essential tools: curl, wget, vim, htop, net-tools
- Sets timezone to UTC
- Configures hostnames for each server

**Check after completion:**
```bash
# Verify tools are installed
ansible all -i inventory.ini -b -m command -a "curl --version"
ansible all -i inventory.ini -b -m command -a "htop --version"

# Check hostnames
ansible all -i inventory.ini -b -m command -a "hostname"
```

#### 1B. Kernel Configuration (Critical for Kubernetes)
```bash
ansible-playbook -i inventory.ini playbooks/01-base-setup/kernel.yml
```

**What this does:**
- **Disables swap** (Kubernetes requirement - swap makes pods slow)
- **Loads kernel modules:** br_netfilter, overlay (needed for container networking)
- **Sets sysctl parameters:** Enables IP forwarding and bridge filtering
- Makes all changes permanent (survives reboots)

**Check after completion:**
```bash
# Verify swap is disabled (should show no swap)
ansible all -i inventory.ini -b -m command -a "free -h"

# Verify kernel modules loaded
ansible all -i inventory.ini -b -m command -a "lsmod | grep br_netfilter"
ansible all -i inventory.ini -b -m command -a "lsmod | grep overlay"

# Verify sysctl settings
ansible all -i inventory.ini -b -m command -a "sysctl net.bridge.bridge-nf-call-iptables"
```
**Expected values:** `net.bridge.bridge-nf-call-iptables = 1`

#### 1C. Firewall Setup (Optional)
```bash
# For production (recommended)
ansible-playbook -i inventory.ini playbooks/01-base-setup/firewall.yml

# For learning/testing (simpler)
ansible all -i inventory.ini -b -m command -a "ufw disable"
```

**What firewall does:**
- Blocks all unnecessary ports
- Opens only: 22 (SSH), 6443 (Kubernetes API), 10250 (kubelet), 2379-2380 (etcd)
- For learning, you might disable it to avoid network issues

---

### 📍 STEP 2: Container Runtime

#### 2A. Install containerd (Container Engine)
```bash
ansible-playbook -i inventory.ini playbooks/02-runtime/containerd.yml
```

**What this does:**
- Downloads and installs **containerd 1.7.22** (replaces Docker)
- Configures containerd to use systemd cgroup driver
- Creates configuration file at `/etc/containerd/config.toml`
- Starts and enables containerd service

**Check after completion:**
```bash
# Verify containerd is running
ansible all -i inventory.ini -b -m command -a "systemctl status containerd --no-pager"

# Check containerd version
ansible all -i inventory.ini -b -m command -a "containerd --version"

# Test container runtime works
ansible all -i inventory.ini -b -m command -a "ctr version"
```

#### 2B. Install CRI Tools
```bash
ansible-playbook -i inventory.ini playbooks/02-runtime/cri-tools.yml
```

**What this does:**
- Installs **crictl** (debug tool for containers)
- Configures it to talk to containerd socket
- Used for troubleshooting container issues

**Check after completion:**
```bash
# Verify crictl works
ansible all -i inventory.ini -b -m command -a "crictl version"

# Test it can list containers (should be empty)
ansible all -i inventory.ini -b -m command -a "crictl ps"
```

---

### 📍 STEP 3: Kubernetes Installation

#### 3A. Install Kubernetes Packages
```bash
ansible-playbook -i inventory.ini playbooks/03-kubernetes/install.yml
```

**What this does:**
- Adds official Kubernetes APT repository (pkgs.k8s.io)
- Installs **kubelet, kubeadm, kubectl** version 1.31.10
- **Holds packages** (prevents automatic updates that could break cluster)

**Check after completion:**
```bash
# Verify Kubernetes tools installed
ansible all -i inventory.ini -b -m command -a "kubeadm version"
ansible all -i inventory.ini -b -m command -a "kubectl version --client"

# Verify kubelet service exists (not running yet - normal)
ansible all -i inventory.ini -b -m command -a "systemctl status kubelet --no-pager"
```

#### 3B. Configure Kubernetes
```bash
ansible-playbook -i inventory.ini playbooks/03-kubernetes/configure.yml
```

**What this does:**
- Configures kubelet to use containerd as container runtime
- Sets up systemd cgroup driver
- Enables kubelet service (will start after cluster init)

---

### 📍 STEP 4: High Availability Setup

#### 4A. Setup Load Balancer
```bash
ansible-playbook -i inventory.ini playbooks/04-ha-setup/lb-haproxy.yml
```

**What this does:**
- Installs **HAProxy** on the load balancer server
- Configures it to listen on port 6443
- Routes traffic to all 3 master servers
- Sets up stats page on port 8404

**Check after completion:**
```bash
# Verify HAProxy is running
ansible lb -i inventory.ini -b -m command -a "systemctl status haproxy --no-pager"

# Test load balancer port is open
curl -v --connect-timeout 5 <YOUR_LB_IP>:6443

# Check HAProxy stats page
curl http://<YOUR_LB_IP>:8404/stats
```

#### 4B. Initialize First Master
```bash
ansible-playbook -i inventory.ini playbooks/04-ha-setup/master-init.yml
```

**What this does:**
- Runs `kubeadm init` on master1
- Creates the Kubernetes cluster with HA endpoint
- Sets up kubectl for root and ansible user
- Generates join commands for other masters and workers

**Check after completion:**
```bash
# Verify cluster is initialized
ansible master1 -i inventory.ini -b -m command -a "kubectl get nodes"

# Check cluster info
ansible master1 -i inventory.ini -b -m command -a "kubectl cluster-info"

# Verify control plane pods
ansible master1 -i inventory.ini -b -m command -a "kubectl get pods -n kube-system"
```
**Expected:** master1 should show as "NotReady" (needs CNI)

---

### 📍 STEP 5: Network Plugin (Makes nodes Ready)

#### 5A. Install Calico CNI
```bash
ansible-playbook -i inventory.ini playbooks/06-network/cni.yml
```

**What this does:**
- Downloads Calico network plugin v3.28.2
- Creates pod network with CIDR 192.168.0.0/16
- Enables pod-to-pod communication across nodes
- Installs network drivers on all nodes

**Check after completion:**
```bash
# Verify nodes are now Ready
ansible master1 -i inventory.ini -b -m command -a "kubectl get nodes"

# Check Calico pods are running
ansible master1 -i inventory.ini -b -m command -a "kubectl get pods -n kube-system -l k8s-app=calico-node"

# Verify CoreDNS is now running (was pending before)
ansible master1 -i inventory.ini -b -m command -a "kubectl get pods -n kube-system -l k8s-app=kube-dns"
```
**Expected:** All pods should show "Running" status

---

### � STEP 6: Join Additional Masters

#### 6A. Add Masters 2 and 3
```bash
ansible-playbook -i inventory.ini playbooks/04-ha-setup/join-masters.yml
```

**What this does:**
- Generates fresh certificate keys (they expire in 2 hours)
- Joins master2 and master3 to the cluster
- Sets up kubectl access on each master
- Creates true High Availability (3 masters)

**Check after completion:**
```bash
# Verify all 3 masters are Ready
ansible master1 -i inventory.ini -b -m command -a "kubectl get nodes"

# Check control plane pods on all masters
ansible master1 -i inventory.ini -b -m command -a "kubectl get pods -n kube-system -o wide | grep -E '(api|etcd|scheduler|controller)'"

# Verify HAProxy sees all masters as UP
curl -s http://<YOUR_LB_IP>:8404/stats | grep master
```

---

### 📍 STEP 7: Join Worker Nodes

#### 7A. Add Workers
```bash
ansible-playbook -i inventory.ini playbooks/05-workers/join-workers.yml
```

**What this does:**
- Generates fresh worker join commands
- Joins worker1 and worker2 to cluster
- Creates test nginx deployment
- Runs final cluster verification

**Final Verification:**
```bash
# Check all nodes are Ready
ansible master1 -i inventory.ini -b -m command -a "kubectl get nodes -o wide"

# Verify cluster info
ansible master1 -i inventory.ini -b -m command -a "kubectl cluster-info"

# Check test deployment
ansible master1 -i inventory.ini -b -m command -a "kubectl get deployment,pods,svc"
```

---

## 🎯 For Your Instructor Presentation

### What You Built:
"I deployed a production-ready Kubernetes cluster with high availability using 6 servers and industry-standard tools."

### Architecture:
```
    Internet → Load Balancer (HAProxy) → 3 Masters → 2 Workers
```

### Key Technologies:
- **containerd**: Modern container runtime (replaced Docker)
- **Calico**: Network plugin for pod communication
- **HAProxy**: Load balancer for high availability
- **kubeadm**: Official Kubernetes cluster management tool

### What You Learned:
1. **Linux system administration** (kernel modules, sysctl, services)
2. **Container technology** (containerd, CRI)
3. **Kubernetes architecture** (masters, workers, control plane)
4. **High Availability concepts** (load balancing, multiple masters)
5. **Network configuration** (CNI, pod networking)
6. **Infrastructure as Code** (Ansible automation)

### Common Issues Fixed:
1. **Kubernetes version format** (must use semantic versioning)
2. **IP address mismatches** (inventory vs vars.yml)
3. **Certificate key expiration** (generate fresh keys)
4. **Network tools missing** (used ss instead of netstat)

---

## 🚨 Troubleshooting Common Issues

### Issue 1: Nodes stuck in "NotReady"
```bash
# Check CNI pods
kubectl get pods -n kube-system -l k8s-app=calico-node

# If CNI failed, reinstall:
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml
```

### Issue 2: HAProxy shows masters as DOWN
```bash
# Check if Kubernetes API is responding
curl -k https://<MASTER_IP>:6443/version

# Restart HAProxy
ansible lb -i inventory.ini -b -m service -a "name=haproxy state=restarted"
```

### Issue 3: Certificate key expired
```bash
# Generate new certificate key from any master
ansible master1 -i inventory.ini -b -m command -a "kubeadm init phase upload-certs --upload-certs"

# Generate new join command
ansible master1 -i inventory.ini -b -m command -a "kubeadm token create --print-join-command"
```

### Issue 4: Ansible connection problems
```bash
# Test basic connectivity
ansible all -i inventory.ini -m ping

# Check SSH key authentication
ssh -i ~/.ssh/your-key ansible@<SERVER_IP>

# Verify sudo access
ansible all -i inventory.ini -b -m command -a "whoami"
```

---

**Created by kamkoum04 for learning Kubernetes and Infrastructure automation**