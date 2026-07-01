# Variables for AWS DevOps Agent Configuration

variable "aws_region" {
  description = "AWS region for DevOps Agent deployment"
  type        = string
  default     = "us-east-1"
}

variable "agent_space_name" {
  description = "Name for the DevOps Agent Space"
  type        = string
  default     = "MyAgentSpace"
}

variable "agent_space_description" {
  description = "Description for the DevOps Agent Space"
  type        = string
  default     = "AgentSpace for monitoring my application"
}

variable "service_account_id" {
  description = "Account ID of the secondary (service) account for cross-account monitoring. Leave empty to skip."
  type        = string
  default     = ""
}

variable "agent_space_arn" {
  description = "ARN of the Agent Space from the primary deployment. Required before deploying the service account resources."
  type        = string
  default     = ""
}

variable "name_postfix" {
  description = "Postfix for resource names to ensure uniqueness"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "aws-devops-agent"
  }
}

# Third-party integrations (mirrors the CDK IntegrationConfig / INTEGRATIONS).
# Populate only the services you want to register; leave the rest unset. The
# whole variable is marked sensitive because it carries OAuth secrets, bearer
# tokens and API keys. Prefer sourcing these from Secrets Manager / SSM in
# production rather than a plaintext tfvars file.
variable "integrations" {
  description = "Optional third-party service integrations to register and associate with the Agent Space."
  sensitive   = true

  type = object({
    dynatrace = optional(object({
      account_urn   = string
      client_id     = string
      client_name   = string
      client_secret = string
      env_id        = string
      resources     = optional(list(string), [])
    }))

    service_now = optional(object({
      instance_url  = string
      client_id     = string
      client_name   = string
      client_secret = string
      instance_id   = optional(string)
    }))

    splunk = optional(object({
      name        = string
      endpoint    = string
      token_name  = string
      token_value = string
    }))

    new_relic = optional(object({
      api_key          = string
      account_id       = string
      endpoint         = string
      region           = optional(string, "US")
      application_ids  = optional(list(string))
      entity_guids     = optional(list(string))
      alert_policy_ids = optional(list(string))
    }))

    git_lab = optional(object({
      target_url   = string
      token_type   = string
      token_value  = string
      project_id   = string
      project_path = string
      group_id     = optional(string)
    }))

    pager_duty = optional(object({
      client_id      = string
      client_name    = string
      client_secret  = string
      scopes         = optional(list(string))
      customer_email = optional(string)
      services       = optional(list(string))
    }))

    datadog = optional(object({
      name           = string
      endpoint       = string
      api_key_value  = string
      api_key_name   = optional(string)
      api_key_header = optional(string)
      description    = optional(string)
    }))
  })

  default = {}
}
