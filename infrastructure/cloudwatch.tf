# ============================================================
# GroceryMate - CloudWatch Monitoring
# File: cloudwatch.tf
# Region: eu-central-1
# ============================================================

# ------------------------------------------------------------
# LOCAL VALUES
# ------------------------------------------------------------
locals {
  ec2_instance_id  = "i-028fed30cdec6d855"
  rds_identifier   = "grocery-db"
  alb_arn_suffix   = "app/myloadbalancer/481478a04238c8ad"
  tg_arn_suffix    = "targetgroup/firsttargetgroup/b1445ca598d60dc6"
  s3_bucket_name   = "grocerymate-avatars-liz2"
  asg_name         = "grocery-asg"
  alert_email      = "theoriginallizard91@gmail.com"
  dashboard_name   = "GroceryMate-Dashboard"
  aws_region       = "eu-central-1"
}

# ------------------------------------------------------------
# SNS TOPIC - Alert notifications
# ------------------------------------------------------------
resource "aws_sns_topic" "grocerymate_alerts" {
  name = "grocerymate-alerts"

  tags = {
    Name    = "grocerymate-alerts"
    Project = "GroceryMate"
  }
}

resource "aws_sns_topic_subscription" "alert_email" {
  topic_arn = aws_sns_topic.grocerymate_alerts.arn
  protocol  = "email"
  endpoint  = local.alert_email
}

# ============================================================
# EC2 ALARMS
# ============================================================

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "grocerymate-ec2-cpu-high"
  alarm_description   = "EC2 CPU utilization exceeded 80% - risk of app slowdown or crash"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = local.ec2_instance_id
  }

  alarm_actions = [aws_sns_topic.grocerymate_alerts.arn]
  ok_actions    = [aws_sns_topic.grocerymate_alerts.arn]

  tags = {
    Project  = "GroceryMate"
    Severity = "Critical"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_status_check_instance" {
  alarm_name          = "grocerymate-ec2-status-check-instance"
  alarm_description   = "EC2 instance status check failed - instance may have crashed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = local.ec2_instance_id
  }

  alarm_actions = [aws_sns_topic.grocerymate_alerts.arn]
  ok_actions    = [aws_sns_topic.grocerymate_alerts.arn]

  tags = {
    Project  = "GroceryMate"
    Severity = "Critical"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_status_check_system" {
  alarm_name          = "grocerymate-ec2-status-check-system"
  alarm_description   = "EC2 system status check failed - underlying hardware issue"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = local.ec2_instance_id
  }

  alarm_actions = [aws_sns_topic.grocerymate_alerts.arn]
  ok_actions    = [aws_sns_topic.grocerymate_alerts.arn]

  tags = {
    Project  = "GroceryMate"
    Severity = "Critical"
  }
}

# ============================================================
# RDS ALARMS
# ============================================================

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "grocerymate-rds-cpu-high"
  alarm_description   = "RDS CPU exceeded 80% - database performance degrading"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.rds_identifier
  }

  alarm_actions = [aws_sns_topic.grocerymate_alerts.arn]
  ok_actions    = [aws_sns_topic.grocerymate_alerts.arn]

  tags = {
    Project  = "GroceryMate"
    Severity = "Critical"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "grocerymate-rds-low-storage"
  alarm_description   = "RDS free storage below 2GB - database may stop accepting writes"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2000000000
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.rds_identifier
  }

  alarm_actions = [aws_sns_topic.grocerymate_alerts.arn]
  ok_actions    = [aws_sns_topic.grocerymate_alerts.arn]

  tags = {
    Project  = "GroceryMate"
    Severity = "Critical"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_high_connections" {
  alarm_name          = "grocerymate-rds-high-connections"
  alarm_description   = "RDS connections exceeded 80 - new users may be unable to log in or checkout"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.rds_identifier
  }

  alarm_actions = [aws_sns_topic.grocerymate_alerts.arn]
  ok_actions    = [aws_sns_topic.grocerymate_alerts.arn]

  tags = {
    Project  = "GroceryMate"
    Severity = "Critical"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_read_latency" {
  alarm_name          = "grocerymate-rds-read-latency"
  alarm_description   = "RDS read latency exceeded 200ms - slow queries affecting page loads"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 0.2
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.rds_identifier
  }

  alarm_actions = [aws_sns_topic.grocerymate_alerts.arn]
  ok_actions    = [aws_sns_topic.grocerymate_alerts.arn]

  tags = {
    Project  = "GroceryMate"
    Severity = "Important"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_write_latency" {
  alarm_name          = "grocerymate-rds-write-latency"
  alarm_description   = "RDS write latency exceeded 200ms - slow writes affecting checkout and user updates"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 0.2
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.rds_identifier
  }

  alarm_actions = [aws_sns_topic.grocerymate_alerts.arn]
  ok_actions    = [aws_sns_topic.grocerymate_alerts.arn]

  tags = {
    Project  = "GroceryMate"
    Severity = "Important"
  }
}

# ============================================================
# ALB ALARMS
# ============================================================

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "grocerymate-alb-unhealthy-hosts"
  alarm_description   = "ALB has unhealthy targets - shop may be unreachable"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = local.alb_arn_suffix
    TargetGroup  = local.tg_arn_suffix
  }

  alarm_actions = [aws_sns_topic.grocerymate_alerts.arn]
  ok_actions    = [aws_sns_topic.grocerymate_alerts.arn]

  tags = {
    Project  = "GroceryMate"
    Severity = "Critical"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "grocerymate-alb-5xx-errors"
  alarm_description   = "ALB 5xx errors exceeded 10 in 5 minutes - customers experiencing server errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = local.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.grocerymate_alerts.arn]
  ok_actions    = [aws_sns_topic.grocerymate_alerts.arn]

  tags = {
    Project  = "GroceryMate"
    Severity = "Critical"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_4xx_errors" {
  alarm_name          = "grocerymate-alb-4xx-errors"
  alarm_description   = "ALB 4xx errors exceeded 50 in 5 minutes - possible broken links or auth issues"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 50
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = local.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.grocerymate_alerts.arn]
  ok_actions    = [aws_sns_topic.grocerymate_alerts.arn]

  tags = {
    Project  = "GroceryMate"
    Severity = "Important"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  alarm_name          = "grocerymate-alb-response-time"
  alarm_description   = "ALB target response time exceeded 2 seconds - poor user experience, risk of abandoned carts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 2
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = local.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.grocerymate_alerts.arn]
  ok_actions    = [aws_sns_topic.grocerymate_alerts.arn]

  tags = {
    Project  = "GroceryMate"
    Severity = "Important"
  }
}

# ============================================================
# S3 - Enable request metrics on avatar bucket
# ============================================================
resource "aws_s3_bucket_metric" "avatars_requests" {
  bucket = local.s3_bucket_name
  name   = "EntireBucket"
}

# ============================================================
# CLOUDWATCH DASHBOARD
# ============================================================
resource "aws_cloudwatch_dashboard" "grocerymate" {
  dashboard_name = local.dashboard_name

  dashboard_body = jsonencode({
    widgets = [

      # ---- EC2 Header ----
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "## 🖥️ EC2 Instance (i-028fed30cdec6d855)"
        }
      },

      # EC2 CPU
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "EC2 CPU Utilization (%)"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", "i-028fed30cdec6d855"]
          ]
          period = 300
          stat   = "Average"
          annotations = {
            horizontal = [{ value = 80, label = "Critical threshold", color = "#ff0000" }]
          }
        }
      },

      # EC2 Network In
      {
        type   = "metric"
        x      = 8
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "EC2 Network In (Bytes)"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", "i-028fed30cdec6d855"]
          ]
          period = 300
          stat   = "Average"
        }
      },

      # EC2 Network Out
      {
        type   = "metric"
        x      = 16
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "EC2 Network Out (Bytes)"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/EC2", "NetworkOut", "InstanceId", "i-028fed30cdec6d855"]
          ]
          period = 300
          stat   = "Average"
        }
      },

      # ---- RDS Header ----
      {
        type   = "text"
        x      = 0
        y      = 7
        width  = 24
        height = 1
        properties = {
          markdown = "## 🐘 RDS PostgreSQL (grocery-db)"
        }
      },

      # RDS CPU
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 6
        height = 6
        properties = {
          title   = "RDS CPU Utilization (%)"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "grocery-db"]
          ]
          period = 300
          stat   = "Average"
          annotations = {
            horizontal = [{ value = 80, label = "Critical threshold", color = "#ff0000" }]
          }
        }
      },

      # RDS Connections
      {
        type   = "metric"
        x      = 6
        y      = 8
        width  = 6
        height = 6
        properties = {
          title   = "RDS Database Connections"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "grocery-db"]
          ]
          period = 300
          stat   = "Average"
          annotations = {
            horizontal = [{ value = 80, label = "Critical threshold", color = "#ff0000" }]
          }
        }
      },

      # RDS Free Storage
      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 6
        height = 6
        properties = {
          title   = "RDS Free Storage Space (Bytes)"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", "grocery-db"]
          ]
          period = 300
          stat   = "Average"
          annotations = {
            horizontal = [{ value = 2000000000, label = "Critical threshold (2GB)", color = "#ff0000" }]
          }
        }
      },

      # RDS Free Memory
      {
        type   = "metric"
        x      = 18
        y      = 8
        width  = 6
        height = 6
        properties = {
          title   = "RDS Free Memory (Bytes)"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", "grocery-db"]
          ]
          period = 300
          stat   = "Average"
        }
      },

      # RDS Read Latency
      {
        type   = "metric"
        x      = 0
        y      = 14
        width  = 12
        height = 6
        properties = {
          title   = "RDS Read Latency (Seconds)"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/RDS", "ReadLatency", "DBInstanceIdentifier", "grocery-db"]
          ]
          period = 300
          stat   = "Average"
          annotations = {
            horizontal = [{ value = 0.2, label = "Important threshold", color = "#ff6600" }]
          }
        }
      },

      # RDS Write Latency
      {
        type   = "metric"
        x      = 12
        y      = 14
        width  = 12
        height = 6
        properties = {
          title   = "RDS Write Latency (Seconds)"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/RDS", "WriteLatency", "DBInstanceIdentifier", "grocery-db"]
          ]
          period = 300
          stat   = "Average"
          annotations = {
            horizontal = [{ value = 0.2, label = "Important threshold", color = "#ff6600" }]
          }
        }
      },

      # ---- ALB Header ----
      {
        type   = "text"
        x      = 0
        y      = 20
        width  = 24
        height = 1
        properties = {
          markdown = "## ⚖️ Application Load Balancer (myloadbalancer)"
        }
      },

      # ALB Request Count
      {
        type   = "metric"
        x      = 0
        y      = 21
        width  = 6
        height = 6
        properties = {
          title   = "ALB Request Count"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app/myloadbalancer/481478a04238c8ad"]
          ]
          period = 300
          stat   = "Sum"
        }
      },

      # ALB 5xx Errors
      {
        type   = "metric"
        x      = 6
        y      = 21
        width  = 6
        height = 6
        properties = {
          title   = "ALB 5xx Errors"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "app/myloadbalancer/481478a04238c8ad"]
          ]
          period = 300
          stat   = "Sum"
          annotations = {
            horizontal = [{ value = 10, label = "Critical threshold", color = "#ff0000" }]
          }
        }
      },

      # ALB 4xx Errors
      {
        type   = "metric"
        x      = 12
        y      = 21
        width  = 6
        height = 6
        properties = {
          title   = "ALB 4xx Errors"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", "app/myloadbalancer/481478a04238c8ad"]
          ]
          period = 300
          stat   = "Sum"
          annotations = {
            horizontal = [{ value = 50, label = "Important threshold", color = "#ff6600" }]
          }
        }
      },

      # ALB Response Time
      {
        type   = "metric"
        x      = 18
        y      = 21
        width  = 6
        height = 6
        properties = {
          title   = "ALB Target Response Time (Seconds)"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "app/myloadbalancer/481478a04238c8ad"]
          ]
          period = 300
          stat   = "Average"
          annotations = {
            horizontal = [{ value = 2, label = "Important threshold", color = "#ff6600" }]
          }
        }
      },

      # ALB Healthy vs Unhealthy
      {
        type   = "metric"
        x      = 0
        y      = 27
        width  = 12
        height = 6
        properties = {
          title   = "ALB Healthy vs Unhealthy Host Count"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", "app/myloadbalancer/481478a04238c8ad", "TargetGroup", "targetgroup/firsttargetgroup/b1445ca598d60dc6", { color = "#00cc00", label = "Healthy" }],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", "app/myloadbalancer/481478a04238c8ad", "TargetGroup", "targetgroup/firsttargetgroup/b1445ca598d60dc6", { color = "#ff0000", label = "Unhealthy" }]
          ]
          period = 60
          stat   = "Maximum"
        }
      },

      # ---- ASG Header ----
      {
        type   = "text"
        x      = 0
        y      = 33
        width  = 24
        height = 1
        properties = {
          markdown = "## 📈 Auto Scaling Group (grocery-asg)"
        }
      },

      # ASG CPU
      {
        type   = "metric"
        x      = 0
        y      = 34
        width  = 12
        height = 6
        properties = {
          title   = "ASG CPU Utilization (%)"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "grocery-asg"]
          ]
          period = 300
          stat   = "Average"
        }
      },

      # ASG Network
      {
        type   = "metric"
        x      = 12
        y      = 34
        width  = 12
        height = 6
        properties = {
          title   = "ASG Network In/Out (Bytes)"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", "grocery-asg", { label = "Network In" }],
            ["AWS/EC2", "NetworkOut", "AutoScalingGroupName", "grocery-asg", { label = "Network Out" }]
          ]
          period = 300
          stat   = "Average"
        }
      },

      # ---- S3 Header ----
      {
        type   = "text"
        x      = 0
        y      = 40
        width  = 24
        height = 1
        properties = {
          markdown = "## 🪣 S3 Bucket (grocerymate-avatars-liz2)"
        }
      },

      # S3 Bucket Size
      {
        type   = "metric"
        x      = 0
        y      = 41
        width  = 8
        height = 6
        properties = {
          title   = "S3 Bucket Size (Bytes)"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/S3", "BucketSizeBytes", "BucketName", "grocerymate-avatars-liz2", "StorageType", "StandardStorage"]
          ]
          period = 86400
          stat   = "Average"
        }
      },

      # S3 Object Count
      {
        type   = "metric"
        x      = 8
        y      = 41
        width  = 8
        height = 6
        properties = {
          title   = "S3 Number of Objects"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/S3", "NumberOfObjects", "BucketName", "grocerymate-avatars-liz2", "StorageType", "AllStorageTypes"]
          ]
          period = 86400
          stat   = "Average"
        }
      },

      # S3 GET Requests
      {
        type   = "metric"
        x      = 16
        y      = 41
        width  = 8
        height = 6
        properties = {
          title   = "S3 GET Requests (Avatar Fetches)"
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          metrics = [
            ["AWS/S3", "GetRequests", "BucketName", "grocerymate-avatars-liz2", "FilterId", "EntireBucket"]
          ]
          period = 300
          stat   = "Sum"
        }
      }
    ]
  })
}
