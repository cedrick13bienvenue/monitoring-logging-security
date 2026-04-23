variable "aws_region" {
  description = "AWS region where all resources will be deployed"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Tag prefix applied to all resources for easy identification"
  type        = string
  default     = "monitoring-lab"
}

variable "environment" {
  description = "Deployment environment: dev | staging | production"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be one of: dev, staging, production"
  }
}

variable "my_ip" {
  description = "Your public IP in CIDR notation (x.x.x.x/32) — restricts SSH access to the monitoring server"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the monitoring server"
  type        = string
  default     = "t3.micro"
}

variable "public_key_path" {
  description = "Path to the SSH public key file on your local machine"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
