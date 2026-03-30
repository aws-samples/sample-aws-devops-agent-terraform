# AWS DevOps Agent Resources

# Wait for IAM roles to propagate before creating the Agent Space
resource "time_sleep" "wait_for_iam_propagation" {
  depends_on = [
    aws_iam_role.devops_agentspace,
    aws_iam_role_policy_attachment.devops_agentspace_access,
    aws_iam_role_policy.devops_agentspace_inline,
    aws_iam_role.devops_operator,
    aws_iam_role_policy_attachment.devops_operator_access
  ]

  create_duration = "30s"
}

# Create the Agent Space with Operator App (matches CDK DevOpsAgentStack)
resource "awscc_devopsagent_agent_space" "main" {
  name        = var.agent_space_name
  description = var.agent_space_description

  operator_app = {
    iam = {
      operator_app_role_arn = aws_iam_role.devops_operator.arn
    }
  }

  depends_on = [
    time_sleep.wait_for_iam_propagation
  ]
}

# Associate the primary AWS account for monitoring
resource "awscc_devopsagent_association" "primary_aws_account" {
  agent_space_id = awscc_devopsagent_agent_space.main.id
  service_id     = "aws"

  configuration = {
    aws = {
      assumable_role_arn = aws_iam_role.devops_agentspace.arn
      account_id         = data.aws_caller_identity.current.account_id
      account_type       = "monitor"
      resources          = []
    }
  }

  depends_on = [
    awscc_devopsagent_agent_space.main
  ]
}

# Associate the service account for cross-account monitoring (optional)
resource "awscc_devopsagent_association" "secondary_aws_account" {
  count = var.service_account_id != "" && var.agent_space_arn != "" ? 1 : 0

  agent_space_id = awscc_devopsagent_agent_space.main.id
  service_id     = "aws"

  configuration = {
    source_aws = {
      assumable_role_arn = aws_iam_role.secondary_account[0].arn
      account_id         = var.service_account_id
      account_type       = "source"
    }
  }

  depends_on = [
    awscc_devopsagent_association.primary_aws_account
  ]
}
