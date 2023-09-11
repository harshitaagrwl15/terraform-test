# AWS provider configuration
provider "aws" {
  region = "us-east-1"  # Change to your desired region
}

# List of child account IDs
variable "child_account_ids" {
  default = ["account_id_1", "account_id_2"]  # Add your child account IDs
}

# Create an S3 bucket for centralized billing data
resource "aws_s3_bucket" "billing_bucket" {
  bucket = "centralized-billing-data"
  acl    = "private"
}

# Enable AWS Cost and Usage Reports for each child account
resource "aws_cur_report_definition" "cur_definitions" {
  count         = length(var.child_account_ids)
  name          = "CUR-${var.child_account_ids[count.index]}"
  time_unit     = "HOURLY"
  format        = "textORcsv"
  compression   = "ZIP"
  additional_artifacts = ["REDSHIFT", "ATHENA"]
  s3_bucket     = aws_s3_bucket.billing_bucket.id
  report_name   = "cur-${var.child_account_ids[count.index]}"
  refresh_closed_reports = true
}

# Create AWS Budgets for each child account
resource "aws_budgets_budget" "budgets" {
  count        = length(var.child_account_ids)
  name         = "Budget-${var.child_account_ids[count.index]}"
  time_period  = "MONTHLY"
  budget_type  = "COST"
  limit_amount = 1000  # Adjust your budget limit as needed
  cost_filters = {
    LinkedAccount = var.child_account_ids[count.index]
  }
}

# Create CloudWatch Alarms for each child account (customize as needed)
resource "aws_cloudwatch_metric_alarm" "spending_alarms" {
  count               = length(var.child_account_ids)
  alarm_name          = "SpendingAlarm-${var.child_account_ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 3600
  statistic           = "Maximum"
  threshold           = 100.0  # Set your spending threshold
  alarm_description   = "This metric monitors estimated charges."
  alarm_actions       = [aws_sns_topic.spending_alerts.arn]
  dimensions = {
    ServiceName = "AmazonEC2"  # Customize as needed
  }
}

# Create an SNS topic for spending alerts
resource "aws_sns_topic" "spending_alerts" {
  name = "SpendingAlerts"
}

# Set up AWS QuickSight (assuming QuickSight resources and permissions are already configured)
# Create QuickSight data sources and dashboard, and grant permissions as needed.
# Refer to AWS QuickSight Terraform documentation for specific configurations.

# Output child account IDs and relevant resources (optional)
output "child_account_ids" {
  value = var.child_account_ids
}

output "billing_bucket_name" {
  value = aws_s3_bucket.billing_bucket.id
}

output "quick_sight_dashboard_url" {
  value = "URL_TO_QUICKSIGHT_DASHBOARD"
}
