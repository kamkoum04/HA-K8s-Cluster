#!/bin/bash
# Kubernetes User Creation and Testing Script
# Enhanced script to create users, assign roles, and test permissions

set -e

SCRIPT_DIR="$(dirname "$0")"
KUBECONFIG_FILE="$SCRIPT_DIR/kubeconfig"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_test() {
    echo -e "${CYAN}[TEST]${NC} $1"
}

# Check if kubeconfig exists
if [ ! -f "$KUBECONFIG_FILE" ]; then
    print_error "kubeconfig file not found at $KUBECONFIG_FILE"
    exit 1
fi

# Available roles
show_available_roles() {
    echo ""
    echo "📋 Available Roles:"
    echo "1. cluster-administrator    - Full cluster access"
    echo "2. namespace-administrator  - Full namespace access"
    echo "3. read-only-user          - Read-only access"
    echo "4. pod-exec-user           - Pod exec permissions only"
    echo ""
}

# Function to create user
create_user() {
    local username=$1
    local role=$2
    local namespace=${3:-"default"}
    
    print_status "Creating user: $username with role: $role"
    
    # Create private key
    print_status "Creating private key..."
    openssl genrsa -out ${username}.key 2048
    
    # Create certificate signing request
    print_status "Creating CSR..."
    openssl req -new -key ${username}.key -out ${username}.csr -subj "/CN=${username}/O=system:authenticated"
    
    # Create CertificateSigningRequest resource
    print_status "Creating K8s CSR..."
    cat <<EOF | kubectl --kubeconfig="$KUBECONFIG_FILE" apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${username}
spec:
  request: $(cat ${username}.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF

    # Approve the certificate
    print_status "Approving certificate..."
    kubectl --kubeconfig="$KUBECONFIG_FILE" certificate approve ${username}
    
    # Get the certificate
    print_status "Extracting certificate..."
    kubectl --kubeconfig="$KUBECONFIG_FILE" get csr ${username} -o jsonpath='{.status.certificate}' | base64 -d > ${username}.crt
    
    # Create kubeconfig for user
    print_status "Creating kubeconfig..."
    CLUSTER_NAME=$(kubectl --kubeconfig="$KUBECONFIG_FILE" config view --minify -o jsonpath='{.clusters[0].name}')
    SERVER=$(kubectl --kubeconfig="$KUBECONFIG_FILE" config view --minify -o jsonpath='{.clusters[0].cluster.server}')
    
    # Create kubeconfig with embedded certificates
    kubectl --kubeconfig="${username}-kubeconfig" config set-cluster ${CLUSTER_NAME} --server=${SERVER} --insecure-skip-tls-verify=true
    kubectl --kubeconfig="${username}-kubeconfig" config set-credentials ${username} --client-certificate=${username}.crt --client-key=${username}.key --embed-certs=true
    kubectl --kubeconfig="${username}-kubeconfig" config set-context ${username}-context --cluster=${CLUSTER_NAME} --user=${username}
    kubectl --kubeconfig="${username}-kubeconfig" config use-context ${username}-context
    
    # Assign role to user
    print_status "Assigning role to user..."
    if [ "$role" = "namespace-administrator" ]; then
        # Create namespace if it doesn't exist
        kubectl --kubeconfig="$KUBECONFIG_FILE" create namespace ${namespace} --dry-run=client -o yaml | kubectl --kubeconfig="$KUBECONFIG_FILE" apply -f -
        
        # Create RoleBinding for namespace
        kubectl --kubeconfig="$KUBECONFIG_FILE" create rolebinding ${username}-${role}-binding \
            --clusterrole=${role} \
            --user=${username} \
            --namespace=${namespace}
    else
        # Create ClusterRoleBinding
        kubectl --kubeconfig="$KUBECONFIG_FILE" create clusterrolebinding ${username}-${role}-binding \
            --clusterrole=${role} \
            --user=${username}
    fi
    
    print_success "User $username created successfully!"
    print_status "Kubeconfig file: ${username}-kubeconfig"
    print_status "Role assigned: $role"
    
    # Cleanup temp files
    rm -f ${username}.key ${username}.csr ${username}.crt
    
    # Clean up CSR
    kubectl --kubeconfig="$KUBECONFIG_FILE" delete csr ${username}
}

# Function to test user permissions
test_user_permissions() {
    local username=$1
    local role=$2
    local namespace=${3:-"default"}
    
    if [ ! -f "${username}-kubeconfig" ]; then
        print_error "User kubeconfig not found: ${username}-kubeconfig"
        return 1
    fi
    
    print_status "Testing permissions for user: $username with role: $role"
    echo ""
    
    case "$role" in
        "cluster-administrator")
            test_cluster_admin_permissions "$username"
            ;;
        "read-only-user")
            test_read_only_permissions "$username"
            ;;
        "pod-exec-user")
            test_pod_exec_permissions "$username"
            ;;
        "namespace-administrator")
            test_namespace_admin_permissions "$username" "$namespace"
            ;;
        *)
            print_error "Unknown role: $role"
            ;;
    esac
}

# Test functions for different roles
test_cluster_admin_permissions() {
    local username=$1
    local kubeconfig="${username}-kubeconfig"
    
    print_test "Testing cluster-administrator permissions for $username..."
    
    # Test 1: Can list nodes
    print_test "1. Can list nodes?"
    if kubectl --kubeconfig="$kubeconfig" get nodes > /dev/null 2>&1; then
        print_success "✓ Can list nodes"
    else
        print_error "✗ Cannot list nodes"
    fi
    
    # Test 2: Can create namespace
    print_test "2. Can create namespace?"
    if kubectl --kubeconfig="$kubeconfig" create namespace test-ns-${username} --dry-run=client -o yaml > /dev/null 2>&1; then
        print_success "✓ Can create namespace"
    else
        print_error "✗ Cannot create namespace"
    fi
    
    # Test 3: Can list all pods in all namespaces
    print_test "3. Can list all pods?"
    if kubectl --kubeconfig="$kubeconfig" get pods --all-namespaces > /dev/null 2>&1; then
        print_success "✓ Can list all pods"
    else
        print_error "✗ Cannot list all pods"
    fi
    
    # Test 4: Can create deployment
    print_test "4. Can create deployment?"
    if kubectl --kubeconfig="$kubeconfig" create deployment test-deploy --image=nginx --dry-run=client -o yaml > /dev/null 2>&1; then
        print_success "✓ Can create deployment"
    else
        print_error "✗ Cannot create deployment"
    fi
}

test_read_only_permissions() {
    local username=$1
    local kubeconfig="${username}-kubeconfig"
    
    print_test "Testing read-only permissions for $username..."
    
    # Test 1: Can list pods
    print_test "1. Can list pods?"
    if kubectl --kubeconfig="$kubeconfig" get pods > /dev/null 2>&1; then
        print_success "✓ Can list pods"
    else
        print_error "✗ Cannot list pods"
    fi
    
    # Test 2: Can list services
    print_test "2. Can list services?"
    if kubectl --kubeconfig="$kubeconfig" get services > /dev/null 2>&1; then
        print_success "✓ Can list services"
    else
        print_error "✗ Cannot list services"
    fi
    
    # Test 3: Cannot create pods
    print_test "3. Cannot create pods?"
    if kubectl --kubeconfig="$kubeconfig" create pod test-pod --image=nginx --dry-run=client -o yaml > /dev/null 2>&1; then
        print_error "✗ Should not be able to create pods"
    else
        print_success "✓ Correctly cannot create pods"
    fi
    
    # Test 4: Cannot delete pods
    print_test "4. Cannot delete resources?"
    if kubectl --kubeconfig="$kubeconfig" delete pod nonexistent-pod > /dev/null 2>&1; then
        print_error "✗ Should not be able to delete pods"
    else
        print_success "✓ Correctly cannot delete pods"
    fi
    
    # Test 5: Can view deployments
    print_test "5. Can view deployments?"
    if kubectl --kubeconfig="$kubeconfig" get deployments > /dev/null 2>&1; then
        print_success "✓ Can view deployments"
    else
        print_error "✗ Cannot view deployments"
    fi
}

test_pod_exec_permissions() {
    local username=$1
    local kubeconfig="${username}-kubeconfig"
    local test_pod_name="test-pod-for-exec-$$" # Add process ID for uniqueness
    local test_namespace="default"

    # Defer the cleanup of the pod using a trap on EXIT.
    # This ensures the pod is deleted even if the script fails.
    trap 'print_status "Cleaning up temporary pod..."; kubectl --kubeconfig="$KUBECONFIG_FILE" delete pod $test_pod_name -n $test_namespace --ignore-not-found=true > /dev/null 2>&1' EXIT

    print_test "Testing pod-exec permissions for $username..."

    # Step 1: Create a temporary pod for testing with the admin kubeconfig
    print_status "Creating temporary pod '$test_pod_name' for testing..."
    kubectl --kubeconfig="$KUBECONFIG_FILE" run $test_pod_name --image=nginx:alpine -n $test_namespace > /dev/null
    
    print_status "Waiting for pod to be running..."
    kubectl --kubeconfig="$KUBECONFIG_FILE" wait --for=condition=ready pod/$test_pod_name -n $test_namespace --timeout=120s > /dev/null

    # --- Start of tests using the user's kubeconfig ---

    # Test 1: Can list pods?
    print_test "1. Can list pods in namespace '$test_namespace'?"
    if kubectl --kubeconfig="$kubeconfig" get pods -n $test_namespace > /dev/null 2>&1; then
        print_success "✓ Can list pods"
    else
        print_error "✗ Cannot list pods"
    fi

    # Test 2: Can access pod logs?
    print_test "2. Can access logs for pod '$test_pod_name'?"
    if kubectl --kubeconfig="$kubeconfig" logs $test_pod_name -n $test_namespace > /dev/null 2>&1; then
        print_success "✓ Can access pod logs"
    else
        print_error "✗ Cannot access pod logs"
    fi

    # Test 3: Can exec into the pod?
    print_test "3. Can exec into pod '$test_pod_name'?"
    if kubectl --kubeconfig="$kubeconfig" exec -n $test_namespace $test_pod_name -- /bin/sh -c "echo hello" > /dev/null 2>&1; then
        print_success "✓ Can exec into pod"
    else
        print_error "✗ Cannot exec into pod"
    fi

    # Test 4: Cannot create pods?
    print_test "4. Cannot create pods?"
    if kubectl --kubeconfig="$kubeconfig" create pod another-test-pod --image=nginx --dry-run=client -o yaml > /dev/null 2>&1; then
        print_error "✗ Security Alert: User SHOULD NOT be able to create pods"
    else
        print_success "✓ Correctly cannot create pods"
    fi

    # Explicitly untrap the cleanup command to prevent it from running again.
    trap - EXIT
    # Manually trigger cleanup before function exits.
    print_status "Test complete. Cleaning up temporary pod..."
    kubectl --kubeconfig="$KUBECONFIG_FILE" delete pod $test_pod_name -n $test_namespace --ignore-not-found=true > /dev/null 2>&1
}

test_namespace_admin_permissions() {
    local username=$1
    local namespace=$2
    local kubeconfig="${username}-kubeconfig"
    
    print_test "Testing namespace-administrator permissions for $username in namespace $namespace..."
    
    # Test 1: Can list pods in namespace
    print_test "1. Can list pods in namespace $namespace?"
    if kubectl --kubeconfig="$kubeconfig" get pods -n $namespace > /dev/null 2>&1; then
        print_success "✓ Can list pods in namespace"
    else
        print_error "✗ Cannot list pods in namespace"
    fi
    
    # Test 2: Can create deployment in namespace
    print_test "2. Can create deployment in namespace?"
    if kubectl --kubeconfig="$kubeconfig" create deployment test-deploy --image=nginx -n $namespace --dry-run=client -o yaml > /dev/null 2>&1; then
        print_success "✓ Can create deployment in namespace"
    else
        print_error "✗ Cannot create deployment in namespace"
    fi
    
    # Test 3: Cannot access other namespaces
    print_test "3. Cannot access other namespaces?"
    if kubectl --kubeconfig="$kubeconfig" get pods -n kube-system > /dev/null 2>&1; then
        print_error "✗ Should not access other namespaces"
    else
        print_success "✓ Correctly cannot access other namespaces"
    fi
}

# Function to delete user
delete_user() {
    local username=$1
    
    print_status "Deleting user: $username"
    
    # Delete all possible role bindings
    kubectl --kubeconfig="$KUBECONFIG_FILE" delete clusterrolebinding ${username}-cluster-administrator-binding 2>/dev/null || true
    kubectl --kubeconfig="$KUBECONFIG_FILE" delete clusterrolebinding ${username}-read-only-user-binding 2>/dev/null || true
    kubectl --kubeconfig="$KUBECONFIG_FILE" delete clusterrolebinding ${username}-pod-exec-user-binding 2>/dev/null || true
    
    # Delete namespace role bindings (check all namespaces)
    for ns in $(kubectl --kubeconfig="$KUBECONFIG_FILE" get namespaces -o jsonpath='{.items[*].metadata.name}'); do
        kubectl --kubeconfig="$KUBECONFIG_FILE" delete rolebinding ${username}-namespace-administrator-binding -n $ns 2>/dev/null || true
    done
    
    # Delete kubeconfig file
    rm -f ${username}-kubeconfig
    
    print_success "User $username deleted successfully!"
}

# Main script
case "$1" in
    "create")
        if [ $# -lt 3 ]; then
            echo "Usage: $0 create <username> <role> [namespace]"
            show_available_roles
            exit 1
        fi
        create_user "$2" "$3" "$4"
        ;;
    "test")
        if [ $# -lt 3 ]; then
            echo "Usage: $0 test <username> <role> [namespace]"
            show_available_roles
            exit 1
        fi
        test_user_permissions "$2" "$3" "$4"
        ;;
    "delete")
        if [ $# -lt 2 ]; then
            echo "Usage: $0 delete <username>"
            exit 1
        fi
        delete_user "$2"
        ;;
    "roles")
        show_available_roles
        ;;
    *)
        echo "🔒 Enhanced Kubernetes User Management & Testing Script"
        echo ""
        echo "Usage: $0 <command> [arguments]"
        echo ""
        echo "Commands:"
        echo "  create <username> <role> [namespace]  - Create a new user with specified role"
        echo "  test <username> <role> [namespace]    - Test user permissions"
        echo "  delete <username>                     - Delete a user and all their bindings"
        echo "  roles                                 - Show available roles"
        echo ""
        echo "Examples:"
        echo "  $0 create john cluster-administrator"
        echo "  $0 test john cluster-administrator"
        echo "  $0 create alice namespace-administrator development"
        echo "  $0 test alice namespace-administrator development"
        echo "  $0 create bob read-only-user"
        echo "  $0 test bob read-only-user"
        echo "  $0 delete john"
        show_available_roles
        ;;
esac
