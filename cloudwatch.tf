resource "aws_cloudwatch_metric_alarm" "missing_data_alarm" {
  alarm_name          = "MissingDataAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "MissingDataMetric"
  namespace           = "Dataleak"
  period              = 300
  statistic           = "SampleCount"
  threshold           = 1

  alarm_description = "Alert for missing data from agencies"
  alarm_actions     = ["arn:aws:sns:eu-west-1:123456789012:ErrorInFiles"]

  dimensions = {
    "Agencies" = "All"
  }

  treat_missing_data = "notBreaching"
}
