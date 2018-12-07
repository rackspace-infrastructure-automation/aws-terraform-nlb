/*
* # aws-terraform-nlb
*
* This module provides the functionality to deploy a Network Load Balancer complete with listeners and target groups.
*
* ## Usage:
*this and other examples available [here](examples/)
*
*```
*module "nlb" {
*  source         = "git@github.com:rackspace-infrastructure-automation/aws-terraform-nlb.git?ref=<git tag, branch, or commit hash here>"
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
*      port = 8080
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

  name = "${lookup(var.tg_map[element(local.tg_keys,count.index)],"name", "__UNSET__") == "__UNSET__"
       ? "${var.name}-${element(local.tg_keys,count.index)}-tg"
       : lookup(var.tg_map[element(local.tg_keys,count.index)],"name", "__UNSET__")}"

  port                 = "${lookup(var.tg_map[element(local.tg_keys,count.index)],"port")}"
  protocol             = "TCP"
  deregistration_delay = "${lookup(var.tg_map[element(local.tg_keys,count.index)],"dereg_delay","300")}"
  target_type          = "${lookup(var.tg_map[element(local.tg_keys,count.index)],"target_type","instance")}"

  tags = "${local.tags}"

  health_check {
    protocol            = "${lookup(var.hc_map[element(local.hc_keys,count.index)],"protocol")}"
    healthy_threshold   = "${lookup(var.hc_map[element(local.hc_keys,count.index)],"healthy_threshold","3")}"
    unhealthy_threshold = "${lookup(var.hc_map[element(local.hc_keys,count.index)],"unhealthy_threshold","3")}"
    interval            = "${lookup(var.hc_map[element(local.hc_keys,count.index)],"interval","30")}"
    matcher             = "${lookup(var.hc_map[element(local.hc_keys,count.index)],"matcher","")}"
    path                = "${lookup(var.hc_map[element(local.hc_keys,count.index)],"path","")}"
  }
}

resource "aws_lb_listener" "listener" {
  count = "${length(local.lm_keys)}"

  load_balancer_arn = "${aws_lb.nlb.arn}"
  port              = "${lookup(var.listener_map[element(local.lm_keys,count.index)],"port")}"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.tg.*.arn[count.index]}"
    type             = "forward"
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

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  count           = "${length(local.tg_keys)}"
  actions_enabled = "${var.enable_cloudwatch_alarm_actions}"

  alarm_actions = [
    "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rackspace-support-emergency",
  ]

  alarm_description   = "Unhealthy Host count is above threshold, creating ticket."
  alarm_name          = "NLB Unhealthy Host Count - ${aws_lb.nlb.name}-${aws_lb_target_group.tg.*.name[count.index]}"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    LoadBalancer = "${aws_lb.nlb.arn_suffix}"
    TargetGroup  = "${aws_lb_target_group.tg.*.arn_suffix[count.index]}"
  }

  evaluation_periods = "10"
  metric_name        = "UnHealthyHostCount"
  namespace          = "AWS/NetworkELB"

  ok_actions = [
    "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rackspace-support-emergency",
  ]

  period    = "60"
  statistic = "Maximum"
  threshold = "1"
  unit      = "Count"
}
