variable "aws_region" {
  description = "AWS region for the backend resources"
  type        = string
  default     = "eu-west-1"
}

variable "bucket_name" {
  description = "S3 bucket name for Terraform state storage"
  type        = string
  default     = "cedrick-monitoring-lab-state"
}

variable "dynamodb_table" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "monitoring-lab-lock"
}
