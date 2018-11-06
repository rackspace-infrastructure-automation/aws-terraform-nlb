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
*  source         = "git@github.com:rackspace-infrastructure-automation/aws-terraform-nlb.git?ref=<git tag, branch, or commit hash here>"
*  environment    = "Test"
*  nlb_name       = "MyNLB"
*
*  vpc_id = "vpc-xxxxxxxxxxxxxxxxx"
*  nlb_subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-xxxxxxxxxxxxxxxxx"]
*
*  # enable alarm actions for TG alarms. vars available for these parameters
*  enable_cloudwatch_alarm_actions = "true"
*
*  nlb_tags      = {
*      "role"    = "load-balancer"
*      "contact" = "someone@somewhere.com"
*  }
*
*  nlb_listener_map = {
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
*  nlb_tg_map = {
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
*  nlb_hc_map = {
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
**/

resource "aws_lb" "nlb" {
  name               = "${var.nlb_name}"
  internal           = "${var.nlb_facing == "internal" ? true : false}"
  load_balancer_type = "network"

  enable_cross_zone_load_balancing = "${var.nlb_cross_zone}"

  subnets = ["${var.nlb_subnet_ids}"]
  tags    = "${local.tags}"
}

resource "aws_lb_target_group" "nlb_tg" {
  count = "${length(local.tg_keys)}"

  vpc_id = "${var.vpc_id}"

  name = "${lookup(var.nlb_tg_map[element(local.tg_keys,count.index)],"name", "__UNSET__") == "__UNSET__"
       ? "${var.nlb_name}-${element(local.tg_keys,count.index)}-tg"
       : lookup(var.nlb_tg_map[element(local.tg_keys,count.index)],"name", "__UNSET__")}"

  port                 = "${lookup(var.nlb_tg_map[element(local.tg_keys,count.index)],"port")}"
  protocol             = "TCP"
  deregistration_delay = "${lookup(var.nlb_tg_map[element(local.tg_keys,count.index)],"dereg_delay","300")}"
  target_type          = "${lookup(var.nlb_tg_map[element(local.tg_keys,count.index)],"target_type","instance")}"

  tags = "${local.tags}"

  health_check {
    protocol            = "${lookup(var.nlb_hc_map[element(local.hc_keys,count.index)],"protocol")}"
    healthy_threshold   = "${lookup(var.nlb_hc_map[element(local.hc_keys,count.index)],"healthy_threshold","3")}"
    unhealthy_threshold = "${lookup(var.nlb_hc_map[element(local.hc_keys,count.index)],"unhealthy_threshold","3")}"
    interval            = "${lookup(var.nlb_hc_map[element(local.hc_keys,count.index)],"interval","30")}"
    matcher             = "${lookup(var.nlb_hc_map[element(local.hc_keys,count.index)],"matcher","")}"
    path                = "${lookup(var.nlb_hc_map[element(local.hc_keys,count.index)],"path","")}"
  }
}

resource "aws_lb_listener" "nlb_listener" {
  count = "${length(local.lm_keys)}"

  load_balancer_arn = "${aws_lb.nlb.arn}"
  port              = "${lookup(var.nlb_listener_map[element(local.lm_keys,count.index)],"port")}"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.nlb_tg.*.arn[count.index]}"
    type             = "forward"
  }
}

resource "aws_route53_record" "route53_nlb_cname" {
  count = "${var.route53_zone_id == "__UNSET__" ? 0:1}"

  zone_id = "${var.route53_zone_id}"
  name    = "${var.nlb_name}-${var.environment}-nlb"
  records = ["${aws_lb.nlb.dns_name}"]
  type    = "CNAME"
  ttl     = "5"
}

resource "aws_cloudwatch_metric_alarm" "nlb_unhealthy_hosts" {
  count           = "${length(local.tg_keys)}"
  actions_enabled = "${var.enable_cloudwatch_alarm_actions}"

  alarm_actions = [
    "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rackspace-support-emergency",
  ]

  alarm_description   = "Unhealthy Host count is above threshold, creating ticket."
  alarm_name          = "NLB Unhealthy Host Count - ${aws_lb.nlb.name}-${aws_lb_target_group.nlb_tg.*.name[count.index]}"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    LoadBalancer = "${aws_lb.nlb.arn_suffix}"
    TargetGroup  = "${aws_lb_target_group.nlb_tg.*.arn_suffix[count.index]}"
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
