# Outputs for AWS DevOps Agent Configuration

output "agent_space_id" {
  description = "The ID of the created Agent Space"
  value       = awscc_devopsagent_agent_space.main.id
}

output "agent_space_arn" {
  description = "The ARN of the created Agent Space"
  value       = awscc_devopsagent_agent_space.main.arn
}

output "agent_space_name" {
  description = "The name of the created Agent Space"
  value       = awscc_devopsagent_agent_space.main.name
}

output "devops_agentspace_role_arn" {
  description = "ARN of the DevOps Agent Space IAM role"
  value       = local.agentspace_role_arn
}

output "devops_operator_role_arn" {
  description = "ARN of the DevOps Operator App IAM role"
  value       = local.operator_role_arn
}

output "primary_account_id" {
  description = "Primary (monitoring) account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "primary_account_association_id" {
  description = "ID of the primary AWS account association"
  value       = awscc_devopsagent_association.primary_aws_account.id
}

output "secondary_account_role_arn" {
  description = "ARN of the Secondary Account Role for Agent Space"
  value       = var.agent_space_arn != "" ? var.agent_space_arn != "" && var.service_account_id != "" ? var.agent_space_arn != "" && var.service_account_id != "" ? aws_iam_role.secondary_account[0].arn : null : null : null
}

output "secondary_account_association_id" {
  description = "ID of the secondary AWS account association"
  value       = var.service_account_id != "" ? awscc_devopsagent_association.secondary_aws_account[0].id : null
}

output "aws_region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

# --- Third-party integration outputs ---
# Maps each enabled integration to its registered service ID and association ID.
# Empty when no integrations are configured.

output "integration_service_ids" {
  description = "Service IDs of registered third-party integrations, keyed by service name."
  value = merge(
    local.enable_dynatrace ? { dynatrace = awscc_devopsagent_service.dynatrace[0].service_id } : {},
    local.enable_service_now ? { service_now = awscc_devopsagent_service.service_now[0].service_id } : {},
    local.enable_splunk ? { splunk = awscc_devopsagent_service.splunk[0].service_id } : {},
    local.enable_new_relic ? { new_relic = awscc_devopsagent_service.new_relic[0].service_id } : {},
    local.enable_git_lab ? { git_lab = awscc_devopsagent_service.git_lab[0].service_id } : {},
    local.enable_pager_duty ? { pager_duty = awscc_devopsagent_service.pager_duty[0].service_id } : {},
  )
}

output "integration_association_ids" {
  description = "Association IDs of registered third-party integrations, keyed by service name."
  value = merge(
    local.enable_dynatrace ? { dynatrace = awscc_devopsagent_association.dynatrace[0].association_id } : {},
    local.enable_service_now ? { service_now = awscc_devopsagent_association.service_now[0].association_id } : {},
    local.enable_splunk ? { splunk = awscc_devopsagent_association.splunk[0].association_id } : {},
    local.enable_new_relic ? { new_relic = awscc_devopsagent_association.new_relic[0].association_id } : {},
    local.enable_git_lab ? { git_lab = awscc_devopsagent_association.git_lab[0].association_id } : {},
    local.enable_pager_duty ? { pager_duty = awscc_devopsagent_association.pager_duty[0].association_id } : {},
  )
}
