output "app_log_group_name" {
  description = "CloudWatch log group for container logs"
  value       = aws_cloudwatch_log_group.app.name
}

output "cpu_alarm_name" {
  description = "Name of the EC2 CPU CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.ec2_high_cpu.alarm_name
}
