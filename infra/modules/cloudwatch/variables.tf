variable "project_name" {
  description = "Prefix applied to all resource names"
  type        = string
}

variable "instance_id" {
  description = "EC2 instance ID to attach the CPU alarm to"
  type        = string
}
