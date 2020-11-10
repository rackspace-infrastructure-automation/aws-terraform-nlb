/**
 * # aws-terraform-nlb
 *
 * This module provides the functionality to deploy a Network Load Balancer complete with listeners and target groups.
 *
 * ## Usage:
 *
 * This and other examples available [here](examples/)
 *
 * ```HCL
 * module "nlb" {
 *   source         = "git@github.com:rackspace-infrastructure-automation/aws-terraform-nlb.git//?ref=v0.12.2"
 *
 *   # enable alarm actions for TG alarms. vars available for these parameters
 *   enable_cloudwatch_alarm_actions = true
 *   environment                     = "Test"
 *
 *   hc_map = {
 *     listener1 = {
 *       protocol            = "TCP"
 *       healthy_threshold   = 3
 *       unhealthy_threshold = 3
 *       interval            = 30
 *     }
 *
 *     listener2 = {
 *       protocol            = "HTTP"
 *       healthy_threshold   = 3
 *       unhealthy_threshold = 3
 *       interval            = 30
 *       matcher             = "200-399"
 *       path                = "/"
 *     }
 *   }
 *
 *    listener_map_count = 2
 *
 *   listener_map = {
 *     listener1 = {
 *       port = 80
 *     }
 *
 *     listener2 = {
 *       certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
 *       port            = 443
 *       protocol        = "TLS"
 *     }
 *   }
 *
 *   name       = "MyNLB"
 *   subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-xxxxxxxxxxxxxxxxx"]
 *   vpc_id     = "vpc-xxxxxxxxxxxxxxxxx"
 *
 *
 *   tags = {
 *     "role"    = "load-balancer"
 *     "contact" = "someone@somewhere.com"
 *   }
 *
 *   # if `name` is not defined, then the map index is used for this value
 *   tg_map = {
 *     listener1 = {
 *       name        = "listener1-tg-name"
 *       port        = 80
 *       dereg_delay = 300
 *       target_type = "instance"
 *     }
 *
 *     listener2 = {
 *       name        = "listener2-tg-name"
 *       port        = 8080
 *       dereg_delay = 300
 *       target_type = "instance"
 *     }
 *   }
 * }
 * ```
 *
 * ## Limitations
 *
 * - Current module does not support the use of elastic IPs on the NLB at this time, due to a limitation in generating the SubnetMappings list.  This is expected to be corrected with the release of terraform v0.12.
 *
 * ## Other TF Modules Used
 *
 * Using [aws-terraform-cloudwatch_alarm](https://github.com/rackspace-infrastructure-automation/aws-terraform-cloudwatch_alarm) to create the following CloudWatch Alarms:
 *   - unhealthy_host_count_alarm
 */

terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = ">= 2.20"
  }
}

locals {
  default_health_check = {
    healthy_threshold   = 3
    interval            = 30
    protocol            = "TCP"
    unhealthy_threshold = 3
  }

  default_tg_params = {
    dereg_delay = 300
    target_type = "instance"
  }

  hc_keys = keys(var.hc_map)
  lm_keys = keys(var.listener_map)
  tg_keys = keys(var.tg_map)

  tags = merge(
    var.tags,
    {
      "Environment"     = var.environment
      "ServiceProvider" = "Rackspace"
    },
  )
}

resource "aws_lb" "nlb" {
  name               = var.name
  internal           = var.facing == "internal" ? true : false
  load_balancer_type = "network"

  enable_cross_zone_load_balancing = var.cross_zone

  subnets = var.subnet_ids

  tags = local.tags
}

resource "aws_lb_target_group" "tg" {
  count = length(local.tg_keys)

  vpc_id = var.vpc_id

  name = lookup(
    var.tg_map[element(local.tg_keys, count.index)],
    "name",
    "${var.name}-${element(local.tg_keys, count.index)}-tg",
  )

  deregistration_delay = lookup(
    var.tg_map[element(local.tg_keys, count.index)],
    "dereg_delay",
    "300",
  )
  port = var.tg_map[element(local.tg_keys, count.index)]["port"]
  protocol = upper(
    lookup(
      var.tg_map[element(local.tg_keys, count.index)],
      "protocol",
      "TCP",
    ),
  )
  target_type = lookup(
    var.tg_map[element(local.tg_keys, count.index)],
    "target_type",
    "instance",
  )

  dynamic "stickiness" {
    for_each = lookup(
      var.tg_map[element(local.tg_keys, count.index)],
      "stickiness_placeholder",
      false,
    ) ? toset(["build"]) : toset([])

    content {
      enabled = false
      type    = "lb_cookie"
    }
  }

  health_check {
    healthy_threshold = lookup(
      var.hc_map[element(local.hc_keys, count.index)],
      "healthy_threshold",
      "3",
    )
    interval = lookup(
      var.hc_map[element(local.hc_keys, count.index)],
      "interval",
      "30",
    )
    matcher = lookup(
      var.hc_map[element(local.hc_keys, count.index)],
      "matcher",
      "",
    )
    path     = lookup(var.hc_map[element(local.hc_keys, count.index)], "path", "")
    port     = lookup(var.hc_map[element(local.hc_keys, count.index)], "port", "traffic-port")
    protocol = upper(var.hc_map[element(local.hc_keys, count.index)]["protocol"])
    unhealthy_threshold = lookup(
      var.hc_map[element(local.hc_keys, count.index)],
      "unhealthy_threshold",
      "3",
    )
  }

  tags = local.tags
}

resource "aws_lb_listener" "listener" {
  count = var.listener_map_count

  certificate_arn = lookup(
    var.listener_map[element(local.lm_keys, count.index)],
    "certificate_arn",
    "",
  )
  load_balancer_arn = aws_lb.nlb.arn
  port              = var.listener_map[element(local.lm_keys, count.index)]["port"]
  protocol = upper(
    lookup(
      var.listener_map[element(local.lm_keys, count.index)],
      "protocol",
      "TCP",
    ),
  )

  ssl_policy = upper(
    lookup(
      var.listener_map[element(local.lm_keys, count.index)],
      "protocol",
      "TCP",
    ),
    ) != "TLS" ? "" : lookup(
    var.listener_map[element(local.lm_keys, count.index)],
    "ssl_policy",
    "ELBSecurityPolicy-TLS-1-2-2017-01",
  )

  default_action {
    target_group_arn = lookup(
      var.listener_map[element(local.lm_keys, count.index)],
      "target_group",
      element(aws_lb_target_group.tg.*.arn, count.index),
    )
    type = "forward"
  }
}

resource "aws_route53_record" "route53_record" {
  count = var.create_internal_zone_record ? 1 : 0

  name    = var.internal_record_name
  type    = "A"
  zone_id = var.route_53_hosted_zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_lb.nlb.dns_name
    zone_id                = aws_lb.nlb.zone_id
  }
}

data "null_data_source" "alarm_dimensions" {
  count = length(local.tg_keys)

  inputs = {
    LoadBalancer = aws_lb.nlb.arn_suffix
    TargetGroup  = aws_lb_target_group.tg[count.index].arn_suffix
  }
}

module "unhealthy_host_count_alarm" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-cloudwatch_alarm//?ref=v0.12.0"

  alarm_count              = length(local.tg_keys)
  alarm_description        = "Unhealthy Host count is above threshold, creating ticket."
  alarm_name               = "NLB Unhealthy Host Count - ${aws_lb.nlb.name}"
  comparison_operator      = "GreaterThanOrEqualToThreshold"
  dimensions               = data.null_data_source.alarm_dimensions.*.outputs
  evaluation_periods       = 10
  metric_name              = "UnHealthyHostCount"
  namespace                = "AWS/NetworkELB"
  notification_topic       = var.notification_topic
  period                   = 60
  rackspace_alarms_enabled = var.rackspace_alarms_enabled
  rackspace_managed        = var.rackspace_managed
  severity                 = "emergency"
  statistic                = "Maximum"
  threshold                = 1
  unit                     = "Count"
}
