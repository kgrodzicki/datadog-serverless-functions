# ----------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ----------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "Lambda name."
  type        = string
  default     = "datadog-forwarder"
}

variable "lambda_version" {
  description = "The Lambda Forwarder version."
  type        = string
  default     = "3.4.0"
}

variable "dd_site" {
  description = "Datadog site - datadoghq.com or datadoghq.eu. Datadog env DD_SITE."
  type        = string
  default     = "datadoghq.eu"
}

variable "mem_size" {
  description = "Memory size for the Lambda function."
  type        = number
  default     = 1024
}

variable "reserver_concurrency" {
  description = "Reserved concurrency for the Lambda function."
  type        = number
  default     = 100
}

variable "forward_log" {
  description = "Set to false to disable log forwarding, while keep the forwarder forward other observability data, such as metrics and traces from Lambda functions."
  type        = bool
  default     = true
}

variable "dd_api_key_ssm_name" {
  description = "The SSM name for api key. Datadog env DD_API_KEY_SSM_NAME."
  type        = string
  default     = "/app/lambda-forwarder/dd-api-key"
}

variable "lambda_source_file" {
  description = "Lambda Source file path."
  type        = string
  default     = "../lambda_function.py"
}