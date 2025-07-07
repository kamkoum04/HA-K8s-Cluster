
#!/bin/bash

# Simple script to provision infrastructure and update Ansible configs

# Paths
TERRAFORM_DIR=~/Project/playsoftintern/terrform
ANSIBLE_DIR=~/Project/playsoftintern/ha-k8s-ansible

echo "� Starting Terraform deployment..."

# Run terraform
cd "$TERRAFORM_DIR"
terraform init
terraform apply -auto-approve

echo "� Updating Ansible configuration files..."

# Extract IPs from terraform
lb_ip=$(terraform output -raw lb_ip)
master_ips=($(terraform output -json | jq -r '.master_ips.value[]'))
worker_ips=($(terraform output -json | jq -r '.worker_ips.value[]'))

echo "Load Balancer: $lb_ip"
echo "Masters: ${master_ips[*]}"
echo "Workers: ${worker_ips[*]}"

# Generate inventory.ini
cat > "$ANSIBLE_DIR/inventory.ini" << EOF
[lb]
lb1 ansible_host=$lb_ip

[masters]
master1 ansible_host=${master_ips[0]}
master2 ansible_host=${master_ips[1]}
master3 ansible_host=${master_ips[2]}

[workers]
worker1 ansible_host=${worker_ips[0]}
worker2 ansible_host=${worker_ips[1]}

[all:vars]
ansible_user=ansible
EOF

# Update vars.yml - simple replacement
sed -i "s/lb_ip: \".*\"/lb_ip: \"$lb_ip\"/" "$ANSIBLE_DIR/vars.yml"

# Replace master_ips section cleanly
sed -i '/^master_ips:/,/^[a-zA-Z_]/{ /^[a-zA-Z_]/!d; }' "$ANSIBLE_DIR/vars.yml"
sed -i "/^master_ips:/ a\\
  - \"${master_ips[0]}\"\\
  - \"${master_ips[1]}\"\\
  - \"${master_ips[2]}\"" "$ANSIBLE_DIR/vars.yml"

echo "✅ Terraform deployment completed"
echo "✅ inventory.ini updated"
echo "✅ vars.yml updated"

# Prepare all nodes via SSH
all_ips=("$lb_ip" "${master_ips[@]}" "${worker_ips[@]}")

for ip in "${all_ips[@]}"; do
  echo "🔧 Configuring ansible user on $ip..."

  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@"$ip" "bash -s" <<'EOF'
    id ansible &>/dev/null || adduser --disabled-password --gecos "" ansible
    usermod -aG sudo ansible
    echo "ansible  ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ansible
    mkdir -p /home/ansible/.ssh
    cp /root/.ssh/authorized_keys /home/ansible/.ssh/authorized_keys
    chown -R ansible:ansible /home/ansible/.ssh
    chmod 700 /home/ansible/.ssh
    chmod 600 /home/ansible/.ssh/authorized_keys
EOF

  echo "✅ Done on $ip."
done

echo "🎉 All ready! Now run: cd $ANSIBLE_DIR && ./deploy.sh"
