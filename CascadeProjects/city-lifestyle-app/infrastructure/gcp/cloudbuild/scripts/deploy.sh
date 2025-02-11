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

# Initialize Terraform
echo "Initializing Terraform for ${ENVIRONMENT}..."
terraform -chdir="$TERRAFORM_DIR" init

# Validate Terraform configuration
echo "Validating Terraform configuration..."
terraform -chdir="$TERRAFORM_DIR" validate

# Plan Terraform changes
echo "Planning Terraform changes..."
terraform -chdir="$TERRAFORM_DIR" plan -out=tfplan

# Apply Terraform changes
echo "Applying Terraform changes..."
terraform -chdir="$TERRAFORM_DIR" apply tfplan

# Verify deployment
echo "Verifying deployment..."
terraform -chdir="$TERRAFORM_DIR" output

echo "Deployment to ${ENVIRONMENT} completed successfully!"
