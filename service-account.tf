# Service Account Resources (mirrors CDK ServiceStack)
# Deploys into the secondary (service) account for cross-account monitoring.
# Only created when agent_space_arn is set (after initial deployment).

# Secondary account role — trusted by the Agent Space in the monitoring account
resource "aws_iam_role" "secondary_account" {
  count    = var.agent_space_arn != "" ? 1 : 0
  provider = aws.service

  name               = "DevOpsAgentRole-SecondaryAccount-TF"
  assume_role_policy = data.aws_iam_policy_document.secondary_account_trust[0].json
  description        = "Secondary account role for DevOps Agent Space cross-account access"

  tags = var.tags
}

data "aws_iam_policy_document" "secondary_account_trust" {
  count = var.agent_space_arn != "" ? 1 : 0

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
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [var.agent_space_arn]
    }
  }
}

# Attach AIDevOpsAgentAccessPolicy managed policy
resource "aws_iam_role_policy_attachment" "secondary_account_access" {
  count    = var.agent_space_arn != "" ? 1 : 0
  provider = aws.service

  role       = aws_iam_role.secondary_account[0].name
  policy_arn = "arn:aws:iam::aws:policy/AIDevOpsAgentAccessPolicy"
}

# Inline policy for creating Resource Explorer service-linked role
data "aws_iam_policy_document" "secondary_account_inline" {
  count = var.agent_space_arn != "" ? 1 : 0

  statement {
    sid    = "AllowCreateServiceLinkedRoles"
    effect = "Allow"

    actions = [
      "iam:CreateServiceLinkedRole"
    ]

    resources = [
      "arn:aws:iam::${var.service_account_id}:role/aws-service-role/resource-explorer-2.amazonaws.com/AWSServiceRoleForResourceExplorer"
    ]
  }
}

resource "aws_iam_role_policy" "secondary_account_inline" {
  count    = var.agent_space_arn != "" ? 1 : 0
  provider = aws.service

  name   = "AllowCreateServiceLinkedRoles"
  role   = aws_iam_role.secondary_account[0].id
  policy = data.aws_iam_policy_document.secondary_account_inline[0].json
}

# Echo Lambda function — simple example service (matches CDK ServiceStack)
resource "aws_lambda_function" "echo_service" {
  count    = var.agent_space_arn != "" ? 1 : 0
  provider = aws.service

  function_name = "echo-service-tf"
  description   = "Simple echo service that returns the input event"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  timeout       = 30
  memory_size   = 128

  filename         = data.archive_file.echo_lambda[0].output_path
  source_code_hash = data.archive_file.echo_lambda[0].output_base64sha256

  role = aws_iam_role.echo_service_role[0].arn

  tags = var.tags
}

data "archive_file" "echo_lambda" {
  count       = var.agent_space_arn != "" ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/echo-service.zip"

  source {
    content  = <<-JS
exports.handler = async (event) => {
  console.log('Received event:', JSON.stringify(event, null, 2));

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      message: 'Echo service response',
      echo: event,
      timestamp: new Date().toISOString()
    })
  };
};
JS
    filename = "index.js"
  }
}

# Lambda execution role
resource "aws_iam_role" "echo_service_role" {
  count    = var.agent_space_arn != "" ? 1 : 0
  provider = aws.service

  name               = "echo-service-tf-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "lambda_trust" {
  count = var.agent_space_arn != "" ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "echo_service_basic" {
  count    = var.agent_space_arn != "" ? 1 : 0
  provider = aws.service

  role       = aws_iam_role.echo_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
