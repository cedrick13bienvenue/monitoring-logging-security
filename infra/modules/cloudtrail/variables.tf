variable "project_name" {
  description = "Prefix applied to all resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region — used in the S3 bucket policy condition"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev | staging | production) — controls force_destroy on the S3 bucket"
  type        = string
}
