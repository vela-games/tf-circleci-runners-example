locals {
  today_date = formatdate("YYYY-MM-DD",timestamp())
}

resource "aws_launch_template" "circleci-runner" {
    name                    = var.name
    description             = "${var.name} CircleCI Runner"
    disable_api_termination = false
    image_id                = var.ami
    instance_type           = var.instance_type
    key_name                = var.key_name
    user_data               = var.user_data

    vpc_security_group_ids  = var.vpc_security_group_ids
    
    instance_initiated_shutdown_behavior = "terminate"

    dynamic "block_device_mappings" {
      for_each = var.block_device_mappings

      content {
        device_name = block_device_mappings.value.device_name

        ebs {
          volume_size = block_device_mappings.value.ebs.volume_size
        }
      }
    }
   
    dynamic "iam_instance_profile" {
      for_each = var.iam_instance_profile_arn != "" ? [var.iam_instance_profile_arn] : []

      content {
        arn = iam_instance_profile.value
      }
    }

    dynamic "instance_market_options" {
      for_each = var.spot_instance ? [1] : []

      content {
        market_type = "spot"
      }
    }  

    dynamic "tag_specifications" {
      for_each = var.tag_specifications

      content {
        resource_type = tag_specifications.value.resource_type
        tags          = tag_specifications.value.tags
      }
    }

    tags = var.tags
}

resource "aws_autoscaling_group" "circleci-runner-asg" {
    name                      = var.name
    force_delete              = false
    wait_for_capacity_timeout = "10m"
    min_size                  = var.min_size
    desired_capacity          = var.desired_capacity
    max_size                  = var.max_size
    protect_from_scale_in     = false

    termination_policies = ["OldestInstance", "ClosestToNextInstanceHour"]

    vpc_zone_identifier = var.subnet_ids

    suspended_processes = [
      "AZRebalance"
    ]

    enabled_metrics = [
      "GroupDesiredCapacity",
      "GroupInServiceInstances",
      "GroupMaxSize",
      "GroupMinSize",
      "GroupPendingInstances",
      "GroupStandbyInstances",
      "GroupTerminatingInstances",
      "GroupTotalInstances",
    ]
    
    lifecycle {
        ignore_changes = [
            desired_capacity,
        ]
    }

    launch_template {
      id      = aws_launch_template.circleci-runner.id
      version = "$Latest"
    }

    dynamic "tag" {
      for_each = var.asg_tags

      content {
        key                 = tag.value.key
        propagate_at_launch = tag.value.propagate_at_launch
        value               = tag.value.value
      }
    }
}

resource "aws_autoscaling_schedule" "scale-out" {
  scheduled_action_name     = "${var.name}-scale-out"
  min_size                  = var.min_size
  desired_capacity          = var.max_size
  max_size                  = var.max_size
  start_time                = "${local.today_date}T23:59:00Z"
  recurrence                = var.scale_out_recurrence
  autoscaling_group_name    = aws_autoscaling_group.circleci-runner-asg.name

  lifecycle {
    ignore_changes = [start_time]
  }
}

resource "aws_autoscaling_schedule" "scale-in" {
  scheduled_action_name     = "${var.name}-scale-in"
  min_size                  = var.min_size
  desired_capacity          = var.min_size
  max_size                  = var.max_size
  start_time                = "${local.today_date}T22:59:00Z"
  recurrence                = var.scale_in_recurrence
  autoscaling_group_name    = aws_autoscaling_group.circleci-runner-asg.name

  lifecycle {
    ignore_changes = [start_time]
  }
}