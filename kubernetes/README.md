# Kubernetes RBAC User Management

🔐 **Secure user access control for your Kubernetes cluster**

## What It Does

Creates and manages users with different permission levels:
- **Cluster Administrator** - Full cluster access
- **Namespace Administrator** - Full access to specific namespaces  
- **Read-Only User** - View-only access
- **Pod Exec User** - Can execute commands in pods only

## Files Explained

| File | Purpose |
|------|---------|
| `user-manager.sh` | Main script for user operations |
| `cluster-administrator.yml` | Full cluster access role |
| `namespace-administrator.yml` | Namespace admin role |
| `read-only-user.yml` | Read-only access role |
| `restricted-pod-exec-user.yml` | Pod exec only role |

## Quick Start

### Create Users
```bash
# Create cluster admin
./user-manager.sh create admin cluster-administrator

# Create namespace admin for 'development' namespace
./user-manager.sh create alice namespace-administrator development

# Create read-only user
./user-manager.sh create bob read-only-user

# Create pod exec user
./user-manager.sh create charlie pod-exec-user
```

### Test Users
```bash
# Test admin permissions
./user-manager.sh test admin cluster-administrator

# Test namespace admin
./user-manager.sh test alice namespace-administrator development

# Test read-only user
./user-manager.sh test bob read-only-user
```

### Delete Users
```bash
./user-manager.sh delete admin
./user-manager.sh delete alice
```

## User Permissions

### Cluster Administrator
✅ **Can do everything:**
- List/create/delete nodes
- Manage all namespaces
- Full access to all resources
- Cluster-wide operations

### Namespace Administrator  
✅ **Within assigned namespace:**
- Create/delete pods, services, deployments
- Manage all namespace resources
- Full namespace control

❌ **Cannot:**
- Access other namespaces
- Manage cluster-wide resources

### Read-Only User
✅ **Can view:**
- Pods, services, deployments
- Nodes and namespaces
- Logs and events

❌ **Cannot:**
- Create, update, or delete anything
- Execute commands in pods

### Pod Exec User
✅ **Can:**
- List pods and view logs
- Execute commands inside pods
- Debug applications

❌ **Cannot:**
- Create or delete pods
- Access other resources

## How It Works

1. **Certificate Creation** - Generates private key and certificate
2. **Kubernetes CSR** - Submits certificate signing request
3. **Auto-Approval** - Approves the certificate
4. **Kubeconfig Generation** - Creates user kubeconfig file
5. **Role Binding** - Assigns appropriate permissions
6. **Testing** - Verifies permissions work correctly

## User Files Created

After creating a user, you get:
```bash
alice-kubeconfig    # User's kubeconfig file
```

**Share this file with the user:**
```bash
# User can access cluster with:
export KUBECONFIG=alice-kubeconfig
kubectl get pods -n development
```

## Commands

```bash
# Show available roles
./user-manager.sh roles

# Create user
./user-manager.sh create <username> <role> [namespace]

# Test permissions  
./user-manager.sh test <username> <role> [namespace]

# Delete user
./user-manager.sh delete <username>
```

## Examples

**Development team lead:**
```bash
./user-manager.sh create dev-lead namespace-administrator development
./user-manager.sh test dev-lead namespace-administrator development
```

**Support engineer:**
```bash
./user-manager.sh create support pod-exec-user
./user-manager.sh test support pod-exec-user
```

**Monitoring system:**
```bash
./user-manager.sh create monitoring read-only-user
./user-manager.sh test monitoring read-only-user
```

## Troubleshooting

**Certificate issues:**
```bash
# Check certificate signing requests
kubectl get csr

# Manual approval if needed
kubectl certificate approve <username>
```

**Permission denied:**
```bash
# Check role bindings
kubectl get clusterrolebindings | grep <username>
kubectl get rolebindings --all-namespaces | grep <username>

# Test specific permissions
kubectl auth can-i create pods --as=system:user:<username>
```

**Kubeconfig not working:**
```bash
# Test kubeconfig
kubectl --kubeconfig=<username>-kubeconfig get pods

# Check context
kubectl --kubeconfig=<username>-kubeconfig config current-context
```

## Security Notes

- Certificates are automatically cleaned up
- Private keys are never stored permanently  
- Certificate keys expire in 2 hours for security
- All operations use Kubernetes-native authentication
