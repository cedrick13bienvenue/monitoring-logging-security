output "instance_id" {
  description = "ID of the monitoring EC2 instance"
  value       = aws_instance.monitoring.id
}

output "public_ip" {
  description = "Elastic IP address of the monitoring server"
  value       = aws_eip.monitoring.public_ip
}

output "public_dns" {
  description = "Public DNS hostname of the monitoring server"
  value       = aws_instance.monitoring.public_dns
}
