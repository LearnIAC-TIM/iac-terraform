#!/bin/bash
set -e
cd terraform

[ ! -f "terraform.tfvars" ] && echo "❌ terraform.tfvars ikke funnet!" && exit 1

echo "🚀 Deployer infrastruktur..."
terraform init
terraform plan -out=tfplan
echo ""
read -p "Fortsette med apply? (y/n) " -r
[[ $REPLY =~ ^[Yy]$ ]] && terraform apply tfplan && echo "✅ Deployet!" || echo "❌ Avbrutt"
