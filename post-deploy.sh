#!/bin/bash

# Post-deployment verification script for AWS DevOps Agent

set -e

echo "🔍 AWS DevOps Agent Post-Deployment Verification"
echo "================================================="

# Get outputs from Terraform
echo "📋 Getting Terraform outputs..."

AGENT_SPACE_ID=$(terraform output -raw agent_space_id 2>/dev/null || echo "")

if [ -z "$AGENT_SPACE_ID" ]; then
    echo "❌ Could not get Agent Space ID from Terraform outputs"
    echo "   Make sure Terraform has been applied successfully"
    exit 1
fi

AGENT_SPACE_ARN=$(terraform output -raw agent_space_arn 2>/dev/null || echo "")
AGENTSPACE_ROLE_ARN=$(terraform output -raw devops_agentspace_role_arn 2>/dev/null || echo "")
OPERATOR_ROLE_ARN=$(terraform output -raw devops_operator_role_arn 2>/dev/null || echo "")
REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")

echo "✅ Agent Space ID:       $AGENT_SPACE_ID"
echo "✅ Agent Space ARN:      $AGENT_SPACE_ARN"
echo "✅ Agent Space Role ARN: $AGENTSPACE_ROLE_ARN"
echo "✅ Operator Role ARN:    $OPERATOR_ROLE_ARN"

echo ""
echo "🔍 Verify your setup:"
echo "aws devops-agent get-agent-space --agent-space-id $AGENT_SPACE_ID --region $REGION"
echo ""
echo "aws devops-agent list-associations --agent-space-id $AGENT_SPACE_ID --region $REGION"
echo ""
echo "📋 Access the DevOps Agent console at:"
echo "   https://console.aws.amazon.com/aidevops/"
