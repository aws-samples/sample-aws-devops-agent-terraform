#!/bin/bash

# AWS DevOps Agent Terraform Deployment Script

set -e

echo "🚀 AWS DevOps Agent Terraform Deployment"
echo "========================================"

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform first."
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install AWS CLI first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Create terraform.tfvars if it doesn't exist
if [ ! -f "terraform.tfvars" ]; then
    echo "📝 Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "✅ Please edit terraform.tfvars with your specific configuration"
    echo "   Then run this script again."
    exit 0
fi

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Validate configuration
echo "🔍 Validating Terraform configuration..."
terraform validate

# Plan deployment
echo "📋 Planning deployment..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
read -p "🤔 Do you want to apply this plan? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    rm -f tfplan
    exit 0
fi

# Apply deployment
echo "🚀 Applying deployment..."

if terraform apply tfplan; then
    echo "✅ Deployment successful!"
else
    echo "❌ Deployment failed"
    echo "   Please check the errors above and try running 'terraform apply' manually"
    rm -f tfplan
    exit 1
fi

# Clean up plan file
rm -f tfplan

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Check the outputs above for your Agent Space ARN"
echo "2. Visit https://console.aws.amazon.com/aidevops/ to access the console"
echo ""
echo "📋 For cross-account monitoring (Part 2):"
echo "1. Set service_account_id in terraform.tfvars"
echo "2. Set agent_space_arn to the ARN from the output above"
echo "3. Configure the aws.service provider alias with service account credentials"
echo "4. Run './deploy.sh' again"
