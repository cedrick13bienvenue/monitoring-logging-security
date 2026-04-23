variable "project_name" {
  description = "Prefix applied to all resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region — used to pin the subnet availability zone"
  type        = string
}

variable "my_ip" {
  description = "Your public IP in CIDR notation (x.x.x.x/32) — restricts SSH access"
  type        = string
}
