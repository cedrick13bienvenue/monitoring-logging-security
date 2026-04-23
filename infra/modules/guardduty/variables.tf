variable "project_name" {
  description = "Prefix applied to all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment — controls finding publishing frequency"
  type        = string
}
