output "lambda_arn" {
  value = aws_lambda_function.lambda.arn
}

output "deployment_bucket" {
  value = aws_s3_bucket.files.arn
}