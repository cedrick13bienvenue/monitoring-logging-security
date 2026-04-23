variable "project_name" {
  description = "Prefix applied to all resource names"
  type        = string
}

variable "subnet_id" {
  description = "ID of the public subnet to launch the instance in"
  type        = string
}

variable "sg_id" {
  description = "ID of the security group to attach to the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "public_key_path" {
  description = "Path to the SSH public key file on your local machine"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
