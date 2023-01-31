resource "aws_autoscaling_group" "on_demand" {
  count = var.instance.enable_spot ? 0 : 1

  name_prefix = "${var.resource_names["prefix"]}${var.resource_names["separator"]}"

  vpc_zone_identifier = var.subnet_ids

  min_size         = 1
  desired_capacity = var.instance.desired_capacity
  max_size         = var.instance.desired_capacity
  force_delete     = false

  health_check_type         = "EC2"
  health_check_grace_period = 120

  termination_policies = ["OldestInstance"]
  launch_configuration = aws_launch_configuration.this.id

  dynamic "tag" {
    for_each = local.bastion_runtime_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_launch_configuration.this]
}

resource "aws_autoscaling_group" "on_spot" {
  count = var.instance.enable_spot ? 1 : 0

  name = var.resource_names["prefix"]

  vpc_zone_identifier = var.subnet_ids

  min_size         = 1
  desired_capacity = var.instance.desired_capacity
  max_size         = var.instance.desired_capacity
  force_delete     = false

  health_check_type         = "EC2"
  health_check_grace_period = 120

  termination_policies = ["OldestInstance"]

  capacity_rebalance = true # https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-capacity-rebalancing.html

  mixed_instances_policy {
    instances_distribution {
      on_demand_percentage_above_base_capacity = var.instances_distribution.on_demand_percentage_above_base_capacity
      on_demand_base_capacity                  = var.instances_distribution.on_demand_base_capacity
      spot_allocation_strategy                 = var.instances_distribution.spot_allocation_strategy
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.manual_start.id
        version            = "$Latest"
      }
    }
  }

  dynamic "tag" {
    for_each = local.bastion_runtime_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_schedule" "on_demand_up" {
  count = var.schedule != null && !var.instance.enable_spot ? 1 : 0

  scheduled_action_name = "${local.resource_prefix_with_separator}start"
  recurrence            = var.schedule["start"]
  time_zone             = var.schedule["time_zone"]

  min_size               = 1
  max_size               = var.instance.desired_capacity
  desired_capacity       = var.instance.desired_capacity
  autoscaling_group_name = aws_autoscaling_group.on_demand[0].name
}

resource "aws_autoscaling_schedule" "on_demand_down" {
  count = var.schedule != null && !var.instance.enable_spot ? 1 : 0

  scheduled_action_name = "${local.resource_prefix_with_separator}stop"
  recurrence            = var.schedule["stop"]
  time_zone             = var.schedule["time_zone"]

  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  autoscaling_group_name = aws_autoscaling_group.on_demand[0].name
}

resource "aws_autoscaling_schedule" "on_spot_up" {
  count = var.schedule != null && var.instance.enable_spot ? 1 : 0

  scheduled_action_name = "${local.resource_prefix_with_separator}start"
  recurrence            = var.schedule["start"]
  time_zone             = var.schedule["time_zone"]

  min_size               = 1
  max_size               = var.instance.desired_capacity
  desired_capacity       = var.instance.desired_capacity
  autoscaling_group_name = aws_autoscaling_group.on_spot[0].name
}

resource "aws_autoscaling_schedule" "on_spot_down" {
  count = var.schedule != null && var.instance.enable_spot ? 1 : 0

  scheduled_action_name = "${local.resource_prefix_with_separator}stop"
  recurrence            = var.schedule["stop"]
  time_zone             = var.schedule["time_zone"]

  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  autoscaling_group_name = aws_autoscaling_group.on_spot[0].name
}
