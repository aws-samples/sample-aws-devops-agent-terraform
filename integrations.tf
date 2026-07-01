# Third-party service integrations for the AWS DevOps Agent
# (mirrors the CDK IntegrationsStack in the sample-aws-devops-agent-cdk repo).
#
# Each enabled integration registers an external service
# (awscc_devopsagent_service) and associates it with the Agent Space created
# in devops-agent.tf (awscc_devopsagent_association).
#
# A block is only created when its corresponding entry in var.integrations is
# non-null, so the file is a no-op unless you opt in.
#
# NOTE: Unlike the CDK IntegrationsStack — which is a separate stack that
# requires the Agent Space ID to be wired in after the first deployment — these
# resources reference awscc_devopsagent_agent_space.main directly and therefore
# deploy in the SAME `terraform apply` as the rest of the configuration.
#
# SECURITY: integration credentials are supplied through var.integrations, which
# is marked `sensitive`. For production use, source these values from AWS
# Secrets Manager or SSM Parameter Store instead of committing them to tfvars.

locals {
  # Presence flags. var.integrations is sensitive, so unwrap the boolean with
  # nonsensitive() before using it in `count` (Terraform forbids sensitive
  # values in count/for_each). Only the "is this configured?" boolean is
  # unwrapped — the credential values themselves stay sensitive.
  enable_dynatrace   = nonsensitive(var.integrations.dynatrace != null)
  enable_service_now = nonsensitive(var.integrations.service_now != null)
  enable_splunk      = nonsensitive(var.integrations.splunk != null)
  enable_new_relic   = nonsensitive(var.integrations.new_relic != null)
  enable_git_lab     = nonsensitive(var.integrations.git_lab != null)
  enable_pager_duty  = nonsensitive(var.integrations.pager_duty != null)
  enable_datadog     = nonsensitive(var.integrations.datadog != null)
}

# ---------------------------------------------------------------------------
# Dynatrace
# ---------------------------------------------------------------------------
resource "awscc_devopsagent_service" "dynatrace" {
  count        = local.enable_dynatrace ? 1 : 0
  service_type = "dynatrace"

  service_details = {
    dynatrace = {
      account_urn = var.integrations.dynatrace.account_urn
      authorization_config = {
        o_auth_client_credentials = {
          client_id     = var.integrations.dynatrace.client_id
          client_name   = var.integrations.dynatrace.client_name
          client_secret = var.integrations.dynatrace.client_secret
        }
      }
    }
  }
}

resource "awscc_devopsagent_association" "dynatrace" {
  count          = local.enable_dynatrace ? 1 : 0
  agent_space_id = awscc_devopsagent_agent_space.main.id
  service_id     = awscc_devopsagent_service.dynatrace[0].service_id

  configuration = {
    dynatrace = {
      env_id    = var.integrations.dynatrace.env_id
      resources = var.integrations.dynatrace.resources
    }
  }

  depends_on = [awscc_devopsagent_service.dynatrace]
}

# ---------------------------------------------------------------------------
# ServiceNow
# ---------------------------------------------------------------------------
resource "awscc_devopsagent_service" "service_now" {
  count        = local.enable_service_now ? 1 : 0
  service_type = "servicenow"

  service_details = {
    service_now = {
      instance_url = var.integrations.service_now.instance_url
      authorization_config = {
        o_auth_client_credentials = {
          client_id     = var.integrations.service_now.client_id
          client_name   = var.integrations.service_now.client_name
          client_secret = var.integrations.service_now.client_secret
        }
      }
    }
  }
}

resource "awscc_devopsagent_association" "service_now" {
  count          = local.enable_service_now ? 1 : 0
  agent_space_id = awscc_devopsagent_agent_space.main.id
  service_id     = awscc_devopsagent_service.service_now[0].service_id

  configuration = {
    service_now = {
      # Use an explicit instance_id when provided; otherwise fall back to the
      # instance URL (the CDK sample reused the URL here). The association
      # technically expects a ServiceNow instance identifier, so prefer setting
      # service_now.instance_id in var.integrations.
      instance_id = coalesce(var.integrations.service_now.instance_id, var.integrations.service_now.instance_url)
    }
  }

  depends_on = [awscc_devopsagent_service.service_now]
}

# ---------------------------------------------------------------------------
# Splunk (MCP server, bearer-token auth)
# ---------------------------------------------------------------------------
resource "awscc_devopsagent_service" "splunk" {
  count        = local.enable_splunk ? 1 : 0
  service_type = "mcpserversplunk"

  service_details = {
    mcp_server_splunk = {
      name     = var.integrations.splunk.name
      endpoint = var.integrations.splunk.endpoint
      authorization_config = {
        bearer_token = {
          token_name  = var.integrations.splunk.token_name
          token_value = var.integrations.splunk.token_value
        }
      }
    }
  }
}

resource "awscc_devopsagent_association" "splunk" {
  count          = local.enable_splunk ? 1 : 0
  agent_space_id = awscc_devopsagent_agent_space.main.id
  service_id     = awscc_devopsagent_service.splunk[0].service_id

  configuration = {
    mcp_server_splunk = {
      name     = var.integrations.splunk.name
      endpoint = var.integrations.splunk.endpoint
    }
  }

  depends_on = [awscc_devopsagent_service.splunk]
}

# ---------------------------------------------------------------------------
# New Relic (MCP server, API-key auth)
# ---------------------------------------------------------------------------
resource "awscc_devopsagent_service" "new_relic" {
  count        = local.enable_new_relic ? 1 : 0
  service_type = "mcpservernewrelic"

  service_details = {
    mcp_server_new_relic = {
      authorization_config = {
        api_key = {
          api_key          = var.integrations.new_relic.api_key
          account_id       = var.integrations.new_relic.account_id
          region           = var.integrations.new_relic.region
          application_ids  = var.integrations.new_relic.application_ids
          entity_guids     = var.integrations.new_relic.entity_guids
          alert_policy_ids = var.integrations.new_relic.alert_policy_ids
        }
      }
    }
  }
}

resource "awscc_devopsagent_association" "new_relic" {
  count          = local.enable_new_relic ? 1 : 0
  agent_space_id = awscc_devopsagent_agent_space.main.id
  service_id     = awscc_devopsagent_service.new_relic[0].service_id

  configuration = {
    mcp_server_new_relic = {
      account_id = var.integrations.new_relic.account_id
      endpoint   = var.integrations.new_relic.endpoint
    }
  }

  depends_on = [awscc_devopsagent_service.new_relic]
}

# ---------------------------------------------------------------------------
# GitLab
# ---------------------------------------------------------------------------
resource "awscc_devopsagent_service" "git_lab" {
  count        = local.enable_git_lab ? 1 : 0
  service_type = "gitlab"

  service_details = {
    git_lab = {
      target_url  = var.integrations.git_lab.target_url
      token_type  = var.integrations.git_lab.token_type
      token_value = var.integrations.git_lab.token_value
      group_id    = var.integrations.git_lab.group_id
    }
  }
}

resource "awscc_devopsagent_association" "git_lab" {
  count          = local.enable_git_lab ? 1 : 0
  agent_space_id = awscc_devopsagent_agent_space.main.id
  service_id     = awscc_devopsagent_service.git_lab[0].service_id

  configuration = {
    git_lab = {
      project_id   = var.integrations.git_lab.project_id
      project_path = var.integrations.git_lab.project_path
    }
  }

  depends_on = [awscc_devopsagent_service.git_lab]
}

# ---------------------------------------------------------------------------
# PagerDuty (first-class service_type "pagerduty", OAuth client credentials)
# ---------------------------------------------------------------------------
resource "awscc_devopsagent_service" "pager_duty" {
  count        = local.enable_pager_duty ? 1 : 0
  service_type = "pagerduty"

  service_details = {
    pager_duty = {
      scopes = var.integrations.pager_duty.scopes
      authorization_config = {
        o_auth_client_credentials = {
          client_id     = var.integrations.pager_duty.client_id
          client_name   = var.integrations.pager_duty.client_name
          client_secret = var.integrations.pager_duty.client_secret
        }
      }
    }
  }
}

resource "awscc_devopsagent_association" "pager_duty" {
  count          = local.enable_pager_duty ? 1 : 0
  agent_space_id = awscc_devopsagent_agent_space.main.id
  service_id     = awscc_devopsagent_service.pager_duty[0].service_id

  configuration = {
    pager_duty = {
      customer_email = var.integrations.pager_duty.customer_email
      services       = var.integrations.pager_duty.services
    }
  }

  depends_on = [awscc_devopsagent_service.pager_duty]
}

# ---------------------------------------------------------------------------
# Datadog (registered as a generic MCP server "mcpserver", API-key auth, then
# associated via the Datadog-specific association block)
# ---------------------------------------------------------------------------
resource "awscc_devopsagent_service" "datadog" {
  count        = local.enable_datadog ? 1 : 0
  service_type = "mcpserver"

  service_details = {
    mcp_server = {
      name        = var.integrations.datadog.name
      endpoint    = var.integrations.datadog.endpoint
      description = var.integrations.datadog.description
      authorization_config = {
        api_key = {
          api_key_name   = var.integrations.datadog.api_key_name
          api_key_value  = var.integrations.datadog.api_key_value
          api_key_header = var.integrations.datadog.api_key_header
        }
      }
    }
  }
}

resource "awscc_devopsagent_association" "datadog" {
  count          = local.enable_datadog ? 1 : 0
  agent_space_id = awscc_devopsagent_agent_space.main.id
  service_id     = awscc_devopsagent_service.datadog[0].service_id

  configuration = {
    mcp_server_datadog = {
      name        = var.integrations.datadog.name
      endpoint    = var.integrations.datadog.endpoint
      description = var.integrations.datadog.description
    }
  }

  depends_on = [awscc_devopsagent_service.datadog]
}
