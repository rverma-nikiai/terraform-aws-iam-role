module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.14.1"
  attributes = var.attributes
  delimiter  = var.delimiter
  name       = var.name
  namespace  = var.namespace
  stage      = var.stage
  tags       = var.tags
  enabled    = var.enabled
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = var.principals_services_arns
    }
  }

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.principals_arns
    }
  }
}

module "aggregated_policy" {
  source           = "git::https://github.com/rverma-nikiai/terraform-aws-iam-policy-document-aggregator.git?ref=master"
  source_documents = var.policy_documents
}

resource "aws_iam_policy" "default" {
  count       = var.enabled == "true" ? 1 : 0
  name        = module.label.id
  description = var.policy_description
  policy      = module.aggregated_policy.result_document
}

resource "aws_iam_role" "default" {
  count                = var.enabled == "true" ? 1 : 0
  name                 = module.label.id
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  description          = var.role_description
  max_session_duration = var.max_session_duration
}

resource "aws_iam_role_policy_attachment" "default" {
  count      = var.enabled == "true" ? 1 : 0
  role       = aws_iam_role.default[0].name
  policy_arn = aws_iam_policy.default[0].arn
}

