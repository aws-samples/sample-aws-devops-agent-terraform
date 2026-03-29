# AWS DevOps Agent Terraform Configuration

This Terraform configuration mirrors the [CDK get-started example](https://github.com/aws-samples/sample-aws-devops-agent-cdk), providing an equivalent Infrastructure as Code setup for deploying AWS DevOps Agent resources.

## Overview

AWS DevOps Agent helps you monitor and manage your AWS infrastructure using AI-powered insights. This configuration automates the setup described in the [getting started guide](https://docs.aws.amazon.com/devopsagent/latest/userguide/getting-started-with-aws-devops-agent-getting-started-with-aws-devops-agent-using-terraform.html).

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate permissions
- One AWS account for the monitoring (primary) account
- (Optional) A second AWS account for cross-account monitoring

## What this guide covers

This guide is divided into two parts:

- **Part 1** — Deploy an agent space with an operator app and an AWS association in your monitoring account. After completing this part, the agent can monitor issues in that account.
- **Part 2 (Optional)** — Add a source AWS association for a service account and deploy a cross-account IAM role plus an echo Lambda into that account.

## Resources Created

### Part 1: Monitoring Account

| Resource | Name | Purpose |
|----------|------|---------|
| Agent Space | Configurable | Central agent space with operator app |
| IAM Role | DevOpsAgentRole-AgentSpace-* | Assumed by the agent to monitor the account |
| IAM Role | DevOpsAgentRole-WebappAdmin-* | Operator app role |
| Association | AWS (monitor) | Links the monitoring account |
| Association | AWS (source) | Links the service account (optional) |

### Part 2: Service Account (Optional)

| Resource | Name | Purpose |
|----------|------|---------|
| IAM Role | DevOpsAgentRole-SecondaryAccount-TF | Cross-account role trusted by the Agent Space |
| Lambda | echo-service-tf | Example service |

## Usage

### Part 1: Deploy the Agent Space

1. **Clone and configure**
   ```bash
   git clone <this-repo>
   cd sample-aws-devops-agent-terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars`** with your agent space name and description.

3. **Deploy**
   ```bash
   ./deploy.sh
   ```
   Or manually:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Record the outputs** — note the `agent_space_arn` value for Part 2.

5. **Verify**
   ```bash
   ./post-deploy.sh
   ```

### Part 2 (Optional): Add Cross-Account Monitoring

1. **Set the service account ID** in `terraform.tfvars`:
   ```hcl
   service_account_id = "<YOUR_SERVICE_ACCOUNT_ID>"
   ```

2. **Set the agent space ARN** from Part 1 output:
   ```hcl
   agent_space_arn = "arn:aws:aidevops:us-east-1:<MONITORING_ACCOUNT_ID>:agentspace/<SPACE_ID>"
   ```

3. **Configure the `aws.service` provider** in `main.tf` with credentials for the service account. You can use either a named profile or an assume role:

   Using a profile:
   ```hcl
   provider "aws" {
     alias   = "service"
     region  = var.aws_region
     profile = "your-service-account-profile"
   }
   ```

   Or using assume role:
   ```hcl
   provider "aws" {
     alias  = "service"
     region = var.aws_region
     assume_role {
       role_arn = "arn:aws:iam::<SERVICE_ACCOUNT_ID>:role/OrganizationAccountAccessRole"
     }
   }
   ```

4. **Deploy again**:
   ```bash
   terraform apply
   ```

5. **Test the echo service**:
   ```bash
   aws lambda invoke \
     --function-name echo-service-tf \
     --payload '{"test": "hello world"}' \
     --profile service \
     --region us-east-1 \
     response.json
   cat response.json
   ```

## Configuration Options

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for deployment | `us-east-1` |
| `agent_space_name` | Name for the Agent Space | `MyAgentSpace` |
| `agent_space_description` | Description for the Agent Space | `AgentSpace for monitoring my application` |
| `service_account_id` | Service account ID for cross-account monitoring | `""` |
| `agent_space_arn` | Agent Space ARN (required for Part 2) | `""` |
| `name_postfix` | Postfix for IAM role names | `""` |
| `tags` | Tags for all resources | See variables.tf |

## Troubleshooting

- IAM propagation delays: The configuration includes a 30-second `time_sleep` between IAM role creation and Agent Space creation. The DevOps Agent service validates the operator role's trust policy during Agent Space creation, and this can fail if IAM hasn't fully propagated. If you still see trust policy errors, wait a minute and run `terraform apply` again — the IAM roles will already exist and the apply will pick up where it left off.

## Cleanup

Destroy in reverse order if you deployed Part 2:
```bash
./cleanup.sh
```
Or manually:
```bash
terraform destroy
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
