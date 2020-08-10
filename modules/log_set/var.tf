variable "stage" {
  description = "Stage"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "nginx_subnet" {
  description = "nginx EC2 Subnet"
  type        = string
}


variable "nginx_admin_cidrs" {
  description = "nginx Admin CIDRs"
  type        = list
}


variable "nginx_admin_instance_key" {
  description = "nginx instance Key"
  type        = string
}

variable "nginx_instance_type" {
  description = "nginx Instance Type"
  type        = string
}


variable "timezone" {
  description = "tz database timezone name (e.g. Asia/Tokyo)"
  default     = "UTC"
}

variable "memory" {
  description = "Lambda Function memory in megabytes"
  default     = 256
}

variable "timeout" {
  description = "Lambda Function timeout in seconds"
  default     = 60
}



variable "handler" {
  description = "Lambda Function handler (entrypoint)"
  default     = "main.handler"
}

variable "runtime" {
  description = "Lambda Function runtime"
  default     = "python3.7"
}


variable "starting_position" {
  description = "Kinesis ShardIterator type (see: https://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetShardIterator.html )"
  default     = "TRIM_HORIZON"
}

variable "log_id_field" {
  description = "Key name for unique log ID"
  default     = "log_id"
}

variable "log_type_field" {
  description = "Key name for log type"
  default     = "log_type"
}

variable "log_type_unknown_prefix" {
  description = "Log type prefix for logs without log type field"
  default     = "unknown"
}

variable "log_timestamp_field" {
  description = "Key name for log timestamp"
  default     = "time"
}

variable "tracing_mode" {
  description = "X-Ray tracing mode (see: https://docs.aws.amazon.com/lambda/latest/dg/API_TracingConfig.html )"
  default     = "PassThrough"
}

variable "tags" {
  description = "Tags for Lambda Function"
  type        = map(string)
  default     = {}
}

variable "log_retention_in_days" {
  description = "Lambda Function log retention in days"
  default     = 30
}

variable "instance_ami" {
  description = "instance AMI id"
  default = "ami-05a4cce8936a89f06"
}

variable "lambda_localstack_s3_endpoint" {
  description = "Lambda with Localstack s3 test endpoint"
  default = ""
}


variable "s3_log_prefix" {
  description = "S3 Log Prefix"
  default = "nginx_access"
}
