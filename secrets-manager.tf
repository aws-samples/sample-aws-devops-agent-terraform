# =============================================================================
# Secrets Manager Integration (Optional)
# =============================================================================
# Instead of passing credentials in plaintext via tfvars, reference a
# Secrets Manager secret ARN. The secret should be a JSON object with the
# keys expected by the integration (e.g. client_id, client_name, client_secret).
#
# Usage in terraform.tfvars:
#   dynatrace_secret_arn  = "arn:aws:secretsmanager:us-east-1:123456789012:secret:my-secret"
#   dynatrace_account_urn = "urn:dtaccount:a1b2c3d4-e5f6-7890-abcd-ef1234567890"
#   dynatrace_env_id      = "abc12345"
#   dynatrace_resources   = ["HOST-123", "SERVICE-456"]  # optional resource scoping
#
# The secret JSON should contain:
#   {"client_id": "...", "client_name": "...", "client_secret": "..."}
#
# NOTE: If var.integrations.dynatrace is also set (from integrations.tf),
# this module is skipped — integrations.tf takes precedence.
# =============================================================================

variable "dynatrace_secret_arn" {
  description = "Secrets Manager ARN containing Dynatrace OAuth credentials (JSON with client_id, client_name, client_secret). Set to empty to use plaintext in var.integrations instead."
  type        = string
  default     = ""
}

variable "dynatrace_account_urn" {
  description = "Dynatrace account URN (required when using dynatrace_secret_arn)"
  type        = string
  default     = ""
}

variable "dynatrace_env_id" {
  description = "Dynatrace environment ID (required when using dynatrace_secret_arn)"
  type        = string
  default     = ""
}

variable "dynatrace_resources" {
  description = "Dynatrace resources to scope monitoring (optional, for parity with integrations.tf)"
  type        = list(string)
  default     = []
}

locals {
  # Only use Secrets Manager path if ARN is set AND integrations.dynatrace is NOT set
  # Reuses local.enable_dynatrace from integrations.tf to keep enable-logic in one place
  use_dynatrace_sm = var.dynatrace_secret_arn != "" && !local.enable_dynatrace
}

# Fetch the secret only when the Secrets Manager path is active
data "aws_secretsmanager_secret_version" "dynatrace" {
  count     = local.use_dynatrace_sm ? 1 : 0
  secret_id = var.dynatrace_secret_arn
}

locals {
  # Parse the secret JSON when available
  dynatrace_from_secrets_manager = local.use_dynatrace_sm ? jsondecode(
    data.aws_secretsmanager_secret_version.dynatrace[0].secret_string
  ) : null
}

# Register Dynatrace using credentials from Secrets Manager
resource "awscc_devopsagent_service" "dynatrace_from_sm" {
  count        = local.use_dynatrace_sm ? 1 : 0
  service_type = "dynatrace"

  service_details = {
    dynatrace = {
      account_urn = var.dynatrace_account_urn
      authorization_config = {
        o_auth_client_credentials = {
          client_id     = local.dynatrace_from_secrets_manager.client_id
          client_name   = local.dynatrace_from_secrets_manager.client_name
          client_secret = local.dynatrace_from_secrets_manager.client_secret
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.dynatrace_account_urn != ""
      error_message = "dynatrace_account_urn is required when dynatrace_secret_arn is set."
    }
    precondition {
      condition     = var.dynatrace_env_id != ""
      error_message = "dynatrace_env_id is required when dynatrace_secret_arn is set."
    }
  }
}

# Associate Dynatrace with the agent space
resource "awscc_devopsagent_association" "dynatrace_from_sm" {
  count          = local.use_dynatrace_sm ? 1 : 0
  agent_space_id = awscc_devopsagent_agent_space.main.id
  service_id     = awscc_devopsagent_service.dynatrace_from_sm[0].service_id

  configuration = {
    dynatrace = {
      env_id    = var.dynatrace_env_id
      resources = var.dynatrace_resources
    }
  }

  depends_on = [awscc_devopsagent_service.dynatrace_from_sm]
}
