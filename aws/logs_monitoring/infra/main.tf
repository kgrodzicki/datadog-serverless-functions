# ----------------------------------------------------------------------------------------------------------------------
# DEPLOY A DATADOG FORWARDER LAMBDA IN AWS
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

provider "aws" {
  version = "~> 2.5"
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE DATADOG FORWARDER LAMBDA
# ----------------------------------------------------------------------------------------------------------------------

locals {
  zipName = "aws-dd-forwarder-${var.lambda_version}.zip"
}

resource "aws_lambda_function" "lambda" {
  s3_bucket                      = aws_s3_bucket_object.zip.bucket
  s3_key                         = aws_s3_bucket_object.zip.key
  function_name                  = var.name
  handler                        = "lambda_function.lambda_handler"
  runtime                        = "python3.7"
  timeout                        = 120
  memory_size                    = var.mem_size
  role                           = aws_iam_role.lambda.arn
  source_code_hash               = data.archive_file.lambda_zip.output_md5
  reserved_concurrent_executions = var.reserver_concurrency

  layers = [
    "arn:aws:lambda:${data.aws_region.current.id}:464622532012:layer:Datadog-Python37:11",
    "arn:aws:lambda:${data.aws_region.current.id}:464622532012:layer:Datadog-Trace-Forwarder-Python37:5",
  ]

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      DD_API_KEY_SSM_NAME = var.dd_api_key_ssm_name
      DD_SITE             = var.dd_site
      DD_FORWARD_LOG      = var.forward_log
      DD_LOG_LEVEL        = "INFO"
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE ROLE AND REQUIERD ACCESS
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "lambda" {
  name_prefix = "${var.name}-"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "lambda" {
  name       = "lambda"
  roles      = [aws_iam_role.lambda.name]
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_iam_policy" "lambda" {
  name_prefix = "${var.name}-"
  path        = "/"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:GetParameter"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter${var.dd_api_key_ssm_name}"
    },
    {
      "Action": [
        "logs:Create*",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "tag:GetResources",
        "xray:PutTraceSegments"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE DEPLOYMENT BUCKET
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "files" {
  bucket_prefix = "${var.name}-"
  acl           = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_block" {
  bucket = aws_s3_bucket.files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE DEPLOYMENT ZIP
# ----------------------------------------------------------------------------------------------------------------------

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = local.zipName
  source_file = var.lambda_source_file
}

resource "aws_s3_bucket_object" "zip" {
  bucket = aws_s3_bucket.files.bucket
  key    = local.zipName
  source = local.zipName

  depends_on = [data.archive_file.lambda_zip]

  etag = data.archive_file.lambda_zip.output_md5
}
