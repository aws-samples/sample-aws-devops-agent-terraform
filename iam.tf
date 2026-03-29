# IAM Roles and Policies for AWS DevOps Agent

# Random suffix to ensure unique role names
resource "random_id" "suffix" {
  byte_length = 4
}

# Trust policy for DevOps Agent Space Role
data "aws_iam_policy_document" "devops_agentspace_trust" {
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
  name               = "DevOpsAgentRole-AgentSpace-${var.name_postfix != "" ? var.name_postfix : random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.devops_agentspace_trust.json

  tags = var.tags
}

# Attach AWS managed policy to Agent Space role
resource "aws_iam_role_policy_attachment" "devops_agentspace_managed" {
  role       = aws_iam_role.devops_agentspace.name
  policy_arn = "arn:aws:iam::aws:policy/AIOpsAssistantPolicy"
}

# Attach AIDevOpsAgentAccessPolicy managed policy to Agent Space role
resource "aws_iam_role_policy_attachment" "devops_agentspace_access" {
  role       = aws_iam_role.devops_agentspace.name
  policy_arn = "arn:aws:iam::aws:policy/AIDevOpsAgentAccessPolicy"
}

# Inline policy for creating Resource Explorer service-linked role
data "aws_iam_policy_document" "devops_agentspace_inline" {
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
  name   = "AllowCreateServiceLinkedRoles"
  role   = aws_iam_role.devops_agentspace.id
  policy = data.aws_iam_policy_document.devops_agentspace_inline.json
}

# Trust policy for Operator App Role
data "aws_iam_policy_document" "devops_operator_trust" {
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

# DevOps Operator App Role
resource "aws_iam_role" "devops_operator" {
  name               = "DevOpsAgentRole-WebappAdmin-${var.name_postfix != "" ? var.name_postfix : random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.devops_operator_trust.json

  tags = var.tags
}

# Inline policy for Operator App role
data "aws_iam_policy_document" "devops_operator_inline" {
  statement {
    sid    = "AllowBasicOperatorActions"
    effect = "Allow"

    actions = [
      "aidevops:GetAgentSpace",
      "aidevops:GetAssociation",
      "aidevops:ListAssociations",
      "aidevops:CreateBacklogTask",
      "aidevops:GetBacklogTask",
      "aidevops:UpdateBacklogTask",
      "aidevops:ListBacklogTasks",
      "aidevops:ListChildExecutions",
      "aidevops:ListJournalRecords",
      "aidevops:DiscoverTopology",
      "aidevops:InvokeAgent",
      "aidevops:ListGoals",
      "aidevops:ListRecommendations",
      "aidevops:ListExecutions",
      "aidevops:GetRecommendation",
      "aidevops:UpdateRecommendation",
      "aidevops:CreateKnowledgeItem",
      "aidevops:ListKnowledgeItems",
      "aidevops:GetKnowledgeItem",
      "aidevops:UpdateKnowledgeItem",
      "aidevops:ListPendingMessages",
      "aidevops:InitiateChatForCase",
      "aidevops:EndChatForCase",
      "aidevops:DescribeSupportLevel",
      "aidevops:SendChatMessage"
    ]

    resources = ["arn:aws:aidevops:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:agentspace/*"]
  }

  statement {
    sid    = "AllowSupportOperatorActions"
    effect = "Allow"

    actions = [
      "support:DescribeCases",
      "support:InitiateChatForCase",
      "support:DescribeSupportLevel"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "devops_operator_inline" {
  name   = "AIDevOpsBasicOperatorActionsPolicy"
  role   = aws_iam_role.devops_operator.id
  policy = data.aws_iam_policy_document.devops_operator_inline.json
}
