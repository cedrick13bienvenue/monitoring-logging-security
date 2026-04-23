output "monitoring_server_ip" {
  description = "Elastic IP of the monitoring server — use this to SSH in and access UIs"
  value       = module.compute.public_ip
}

output "monitoring_server_dns" {
  description = "Public DNS hostname of the monitoring server"
  value       = module.compute.public_dns
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "app_log_group" {
  description = "CloudWatch log group for container logs"
  value       = module.cloudwatch.app_log_group_name
}

output "cloudtrail_s3_bucket" {
  description = "S3 bucket storing CloudTrail logs"
  value       = module.cloudtrail.s3_bucket_name
}

output "cloudtrail_trail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = module.cloudtrail.trail_arn
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = module.guardduty.detector_id
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://${module.compute.public_ip}:3001"
}

output "prometheus_url" {
  description = "Prometheus UI URL"
  value       = "http://${module.compute.public_ip}:9090"
}
