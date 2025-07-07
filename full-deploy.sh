#!/bin/bash

# Complete deployment script - runs infrastructure + kubernetes deployment
# This combines script.sh + deploy-k8s.sh for full automation

echo "🚀 Complete HA Kubernetes Cluster Deployment"
echo "============================================="

# Step 1: Run infrastructure provisioning and config updates
echo "📦 Step 1: Provisioning infrastructure and updating configs..."
./script.sh

if [ $? -ne 0 ]; then
    echo "❌ Infrastructure provisioning failed. Stopping."
    exit 1
fi

echo ""
echo "⏳ Waiting 30 seconds for infrastructure to be ready..."
sleep 30

# Step 2: Run Kubernetes deployment
echo "🎯 Step 2: Deploying Kubernetes cluster..."
./deploy-k8s.sh

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Complete HA Kubernetes cluster deployment finished!"
    echo "🔗 Your cluster is ready to use!"
else
    echo "❌ Kubernetes deployment failed."
    exit 1
fi
