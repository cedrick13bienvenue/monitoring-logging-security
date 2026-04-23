output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "monitoring_sg_id" {
  description = "ID of the monitoring security group"
  value       = aws_security_group.monitoring.id
}
