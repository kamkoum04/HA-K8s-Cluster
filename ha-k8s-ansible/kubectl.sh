#!/bin/bash
# Kubernetes Cluster Access Script
# Quick access to your HA Kubernetes cluster

KUBECONFIG_FILE="$(dirname "$0")/kubeconfig"

if [ ! -f "$KUBECONFIG_FILE" ]; then
    echo "❌ kubeconfig file not found!"
    echo "💡 Run this first to get the config:"
    echo "   ansible master1 -i inventory.ini -m fetch -a \"src=/home/ansible/.kube/config dest=./kubeconfig flat=yes\" --become-user=ansible"
    exit 1
fi

echo "🎯 Using kubeconfig: $KUBECONFIG_FILE"
echo "🌐 Cluster endpoint: https://104.248.16.158:6443"
echo ""

# Execute kubectl with the proper config
kubectl --kubeconfig="$KUBECONFIG_FILE" "$@"
