#!/bin/bash
set -e

# Configuration
ENVIRONMENT=$1
TERRAFORM_DIR="terraform/environments/${ENVIRONMENT}"

# Validate input
if [ -z "$ENVIRONMENT" ]; then
    echo "Error: Environment not specified"
    echo "Usage: $0 <environment>"
    exit 1
fi

if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "Error: Environment directory not found: $TERRAFORM_DIR"
    exit 1
fi

if [ "$ENVIRONMENT" == "prod" ]; then
    echo "Error: Cannot destroy production environment"
    exit 1
fi

# Confirmation
read -p "Are you sure you want to destroy the ${ENVIRONMENT} environment? This action cannot be undone. (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Destroy cancelled"
    exit 1
fi

# Initialize Terraform
echo "Initializing Terraform for ${ENVIRONMENT}..."
terraform -chdir="$TERRAFORM_DIR" init

# Plan destroy
echo "Planning destroy operation..."
terraform -chdir="$TERRAFORM_DIR" plan -destroy -out=tfplan

# Confirmation for plan
read -p "Review the plan above. Continue with destroy? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Destroy cancelled"
    exit 1
fi

# Destroy resources
echo "Destroying resources..."
terraform -chdir="$TERRAFORM_DIR" apply tfplan

echo "Destroy of ${ENVIRONMENT} completed successfully!"
