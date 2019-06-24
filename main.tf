/**
 * # aws-terraform-nlb
 *
 * This module provides the functionality to deploy a Network Load Balancer complete with listeners and target groups.
 *
 * ## Usage:
 *this and other examples available [here](examples/)
 *
 *```
 *module "nlb" {
 *  source         = "git@github.com:rackspace-infrastructure-automation/aws-terraform-nlb.git?ref=v0.0.3"
 *  environment    = "Test"
 *  name       = "MyNLB"
 *
 *  vpc_id = "vpc-xxxxxxxxxxxxxxxxx"
 *  subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-xxxxxxxxxxxxxxxxx"]
 *
 *  # enable alarm actions for TG alarms. vars available for these parameters
 *  enable_cloudwatch_alarm_actions = "true"
 *
 *  tags      = {
 *      "role"    = "load-balancer"
 *      "contact" = "someone@somewhere.com"
 *  }
 *
 *  listener_map = {
 *    listener1 = {
 *      port = 80
 *    }
 *
 *    listener2 = {
 *      certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
 *      port     = 443
 *      protocol = "TLS"
 *    }
 *  }
 *
 *  # if `name` is not defined, then the map index is used for this value
 *  tg_map = {
 *    listener1 = {
 *      name       = "listener1-tg-name"
 *      port        = 80
 *      dereg_delay = 300
 *      target_type = "instance"
 *    }
 *
 *    listener2 = {
 *      name       = "listener2-tg-name"
 *      port        = 8080
 *      dereg_delay = 300
 *      target_type = "instance"
 *    }
 *  }
 *
 *  hc_map = {
 *    listener1 = {
 *      protocol            = "TCP"
 *      healthy_threshold   = 3
 *      unhealthy_threshold = 3
 *      interval            = 30
 *    }
 *
 *    listener2 = {
 *      protocol            = "HTTP"
 *      healthy_threshold   = 3
 *      unhealthy_threshold = 3
 *      interval            = 30
 *      matcher             = "200-399"
 *      path                = "/"
 *    }
 *  }
 *}
 *```
 *
 * ## Limitations
 *
 * - Current module does not support the use of elastic IPs on the NLB at this time, due to a limitation in generating the SubnetMappings list.  This is expected to be corrected with the release of terraform v0.12.
 * ## Other TF Modules Used
 * Using [aws-terraform-cloudwatch_alarm](https://github.com/rackspace-infrastructure-automation/aws-terraform-cloudwatch_alarm) to create the following CloudWatch Alarms:
 * 	- unhealthy_host_count_alarm
 */

resource "aws_lb" "nlb" {
  name               = "${var.name}"
  internal           = "${var.facing == "internal" ? true : false}"
  load_balancer_type = "network"

  enable_cross_zone_load_balancing = "${var.cross_zone}"

  subnets = ["${var.subnet_ids}"]
  tags    = "${local.tags}"
}

resource "aws_lb_target_group" "tg" {
  count = "${length(local.tg_keys)}"

  vpc_id = "${var.vpc_id}"

  name = "${lookup(var.tg_map[element(local.tg_keys, count.index)], "name",
                   "${var.name}-${element(local.tg_keys, count.index)}-tg")}"

  port                 = "${lookup(var.tg_map[element(local.tg_keys, count.index)], "port")}"
  protocol             = "TCP"
  deregistration_delay = "${lookup(var.tg_map[element(local.tg_keys, count.index)], "dereg_delay", "300")}"
  target_type          = "${lookup(var.tg_map[element(local.tg_keys, count.index)], "target_type", "instance")}"

  tags = "${local.tags}"

  health_check {
    protocol            = "${lookup(var.hc_map[element(local.hc_keys, count.index)], "protocol")}"
    healthy_threshold   = "${lookup(var.hc_map[element(local.hc_keys, count.index)], "healthy_threshold", "3")}"
    unhealthy_threshold = "${lookup(var.hc_map[element(local.hc_keys, count.index)], "unhealthy_threshold", "3")}"
    interval            = "${lookup(var.hc_map[element(local.hc_keys, count.index)], "interval", "30")}"
    matcher             = "${lookup(var.hc_map[element(local.hc_keys, count.index)], "matcher", "")}"
    path                = "${lookup(var.hc_map[element(local.hc_keys, count.index)], "path", "")}"
  }
}

resource "aws_lb_listener" "listener" {
  count = "${var.listener_map_count}"

  certificate_arn   = "${lookup(var.listener_map[element(local.lm_keys, count.index)], "certificate_arn", "")}"
  load_balancer_arn = "${aws_lb.nlb.arn}"
  port              = "${lookup(var.listener_map[element(local.lm_keys, count.index)], "port")}"
  protocol          = "${lookup(var.listener_map[element(local.lm_keys, count.index)], "protocol", "TCP")}"

  ssl_policy = "${lookup(var.listener_map[element(local.lm_keys, count.index)], "protocol", "TCP") == "TCP" ? "" :
                  lookup(var.listener_map[element(local.lm_keys, count.index)], "ssl_policy",
                         "ELBSecurityPolicy-TLS-1-2-2017-01")}"

  default_action {
    type = "forward"

    target_group_arn = "${lookup(var.listener_map[element(local.lm_keys, count.index)],
                                 "target_group",
                                 element(aws_lb_target_group.tg.*.arn, count.index))}"
  }
}

resource "aws_route53_record" "route53_record" {
  count   = "${var.create_internal_zone_record ? 1 : 0}"
  zone_id = "${var.route_53_hosted_zone_id}"
  name    = "${var.internal_record_name}"
  type    = "A"

  alias {
    evaluate_target_health = true
    name                   = "${aws_lb.nlb.dns_name}"
    zone_id                = "${aws_lb.nlb.zone_id}"
  }
}

data "null_data_source" "alarm_dimensions" {
  count = "${length(local.tg_keys)}"

  inputs = {
    LoadBalancer = "${aws_lb.nlb.arn_suffix}"
    TargetGroup  = "${aws_lb_target_group.tg.*.arn_suffix[count.index]}"
  }
}

module "unhealthy_host_count_alarm" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-cloudwatch_alarm//?ref=v0.0.1"

  alarm_count              = "${length(local.tg_keys)}"
  alarm_description        = "Unhealthy Host count is above threshold, creating ticket."
  alarm_name               = "NLB Unhealthy Host Count - ${aws_lb.nlb.name}"
  comparison_operator      = "GreaterThanOrEqualToThreshold"
  dimensions               = "${data.null_data_source.alarm_dimensions.*.outputs}"
  evaluation_periods       = 10
  metric_name              = "UnHealthyHostCount"
  namespace                = "AWS/NetworkELB"
  notification_topic       = "${var.notification_topic}"
  period                   = 60
  rackspace_alarms_enabled = "${var.rackspace_alarms_enabled}"
  rackspace_managed        = "${var.rackspace_managed}"
  severity                 = "emergency"
  statistic                = "Maximum"
  threshold                = 1
  unit                     = "Count"
}
