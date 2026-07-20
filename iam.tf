# IAM Roles and Policies for AWS DevOps Agent

# Random suffix to ensure unique role names
resource "random_id" "suffix" {
  byte_length = 4
}

# Trust policy for DevOps Agent Space Role
data "aws_iam_policy_document" "devops_agentspace_trust" {
  count = var.existing_agentspace_role_arn == "" ? 1 : 0
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["aidevops.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:aidevops:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:agentspace/*"]
    }
  }
}

# DevOps Agent Space Role
resource "aws_iam_role" "devops_agentspace" {
  count              = var.existing_agentspace_role_arn == "" ? 1 : 0
  name               = "DevOpsAgentRole-AgentSpace-${var.name_postfix != "" ? var.name_postfix : random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.devops_agentspace_trust[0].json

  tags = var.tags
}

# Attach AIDevOpsAgentAccessPolicy managed policy to Agent Space role
resource "aws_iam_role_policy_attachment" "devops_agentspace_access" {
  count      = var.existing_agentspace_role_arn == "" ? 1 : 0
  role       = aws_iam_role.devops_agentspace[0].name
  policy_arn = "arn:aws:iam::aws:policy/AIDevOpsAgentAccessPolicy"
}

# Inline policy for creating Resource Explorer service-linked role
data "aws_iam_policy_document" "devops_agentspace_inline" {
  count = var.existing_agentspace_role_arn == "" ? 1 : 0
  statement {
    sid    = "AllowCreateServiceLinkedRoles"
    effect = "Allow"

    actions = [
      "iam:CreateServiceLinkedRole"
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/resource-explorer-2.amazonaws.com/AWSServiceRoleForResourceExplorer"
    ]
  }
}

resource "aws_iam_role_policy" "devops_agentspace_inline" {
  count  = var.existing_agentspace_role_arn == "" ? 1 : 0
  name   = "AllowCreateServiceLinkedRoles"
  role   = aws_iam_role.devops_agentspace[0].id
  policy = data.aws_iam_policy_document.devops_agentspace_inline[0].json
}

# Trust policy for Operator App Role
data "aws_iam_policy_document" "devops_operator_trust" {
  count = var.existing_operator_role_arn == "" ? 1 : 0
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["aidevops.amazonaws.com"]
    }

    actions = ["sts:AssumeRole", "sts:TagSession"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:aidevops:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:agentspace/*"]
    }
  }
}

# DevOps Operator App Role
resource "aws_iam_role" "devops_operator" {
  count              = var.existing_operator_role_arn == "" ? 1 : 0
  name               = "DevOpsAgentRole-WebappAdmin-${var.name_postfix != "" ? var.name_postfix : random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.devops_operator_trust[0].json

  tags = var.tags
}

# Attach AIDevOpsOperatorAppAccessPolicy managed policy to Operator App role
resource "aws_iam_role_policy_attachment" "devops_operator_access" {
  count      = var.existing_operator_role_arn == "" ? 1 : 0
  role       = aws_iam_role.devops_operator[0].name
  policy_arn = "arn:aws:iam::aws:policy/AIDevOpsOperatorAppAccessPolicy"
}
