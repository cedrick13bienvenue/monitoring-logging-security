output "trail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.main.arn
}

output "s3_bucket_name" {
  description = "S3 bucket storing CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_logs.bucket
}

output "cloudtrail_log_group" {
  description = "CloudWatch log group receiving real-time CloudTrail events"
  value       = aws_cloudwatch_log_group.cloudtrail.name
}
