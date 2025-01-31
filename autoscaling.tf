resource "aws_autoscaling_group" "this" {
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
      on_demand_percentage_above_base_capacity = var.instance.enable_spot ? var.instances_distribution.on_demand_percentage_above_base_capacity : 100
      on_demand_base_capacity                  = var.instance.enable_spot ? var.instances_distribution.on_demand_base_capacity : var.instance.desired_capacity
      spot_allocation_strategy                 = var.instance.enable_spot ? var.instances_distribution.spot_allocation_strategy : "lowest-price"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.this.id
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

resource "aws_autoscaling_schedule" "up" {
  count = var.schedule != null ? 1 : 0

  scheduled_action_name = "${local.resource_prefix_with_separator}start"
  recurrence            = var.schedule["start"]
  time_zone             = var.schedule["time_zone"]

  min_size               = 1
  max_size               = var.instance.desired_capacity
  desired_capacity       = var.instance.desired_capacity
  autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "aws_autoscaling_schedule" "down" {
  count = var.schedule != null ? 1 : 0

  scheduled_action_name = "${local.resource_prefix_with_separator}stop"
  recurrence            = var.schedule["stop"]
  time_zone             = var.schedule["time_zone"]

  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  autoscaling_group_name = aws_autoscaling_group.this.name
}
