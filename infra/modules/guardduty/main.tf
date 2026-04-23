resource "aws_guardduty_detector" "main" {
  enable = true

  finding_publishing_frequency = var.environment == "production" ? "FIFTEEN_MINUTES" : "SIX_HOURS"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
