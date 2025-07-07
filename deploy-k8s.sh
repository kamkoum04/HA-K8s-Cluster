#!/bin/bash

# Deploy Kubernetes HA cluster using Ansible
# Run this after script.sh completes

ANSIBLE_DIR=~/Project/playsoftintern/ha-k8s-ansible

echo "🚀 Starting Kubernetes HA Cluster Deployment..."
echo "📁 Working directory: $ANSIBLE_DIR"

# Change to ansible directory
cd "$ANSIBLE_DIR"

# Check if inventory and vars files exist
if [ ! -f "inventory.ini" ]; then
    echo "❌ Error: inventory.ini not found. Please run script.sh first."
    exit 1
fi

if [ ! -f "vars.yml" ]; then
    echo "❌ Error: vars.yml not found. Please run script.sh first."
    exit 1
fi

echo "✅ Configuration files found"
echo "🔍 Checking connectivity to nodes..."

# Test connectivity to all nodes
ansible all -i inventory.ini -m ping

if [ $? -ne 0 ]; then
    echo "❌ Error: Cannot connect to some nodes. Please check SSH access."
    echo "💡 Tip: You may need to run setup-ssh.sh first to configure SSH access."
    exit 1
fi

echo "✅ All nodes are reachable"
echo "🎯 Starting Ansible playbook deployment..."

# Run the main deployment playbook
ansible-playbook -i inventory.ini deploy.yml

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Kubernetes HA Cluster deployment completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "  1. SSH to any master node: ssh ansible@<master-ip>"
    echo "  2. Check cluster status: kubectl get nodes"
    echo "  3. Get cluster info: kubectl cluster-info"
    echo ""
    echo "🔧 Useful commands:"
    echo "  • kubectl get pods --all-namespaces"
    echo "  • kubectl get svc --all-namespaces"
    echo "  • kubectl describe nodes"
else
    echo "❌ Deployment failed. Check the output above for errors."
    exit 1
fi
