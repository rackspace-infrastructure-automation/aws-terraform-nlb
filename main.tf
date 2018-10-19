resource "aws_lb" "nlb" {
  name               = "${var.nlb_name}"
  internal           = "${var.nlb_facing == "internal" ? true : false}"
  load_balancer_type = "network"

  idle_timeout = "${var.nlb_idle_timeout}"

  enable_cross_zone_load_balancing = "${var.nlb_cross_zone}"

  subnets = ["${var.nlb_subnet_ids}"]
  tags    = "${var.nlb_tags}"

  access_logs {
    bucket  = "${var.nlb_al_bucket == "__UNSET__" ? element(aws_s3_bucket.nlb_log_bucket.*.id,0) : var.nlb_al_bucket}"
    prefix  = "AWSLogs"
    enabled = true
  }

  /*
  # there is no graceful way to define a variable number of subnet mappings
  see:
  https://github.com/hashicorp/terraform/issues/7034
  https://serverfault.com/questions/833810/terraform-use-nested-loops-with-count

  subnet_mapping {
    subnet_id     = "${var.subnet_public[0]}"
    allocation_id = "eipalloc-54157069"
  }
  subnet_mapping {
    subnet_id     = "${var.subnet_public[1]}"
    allocation_id = "eipalloc-8d096cb0"
  }
  */
}

resource "aws_lb_target_group" "nlb_tg" {
  count = "${length(local.tg_keys)}"

  vpc_id = "${var.vpc_id}"

  name = "${lookup(var.nlb_tg_map[element(local.tg_keys,count.index)],"name", "__UNSET__") == "__UNSET__"
       ? "${var.nlb_name}-${element(local.tg_keys,count.index)}-tg"
       : lookup(var.nlb_tg_map[element(local.tg_keys,count.index)],"name", "__UNSET__")}"

  port                 = "${lookup(var.nlb_tg_map[element(local.tg_keys,count.index)],"port")}"
  protocol             = "${lookup(var.nlb_tg_map[element(local.tg_keys,count.index)],"protocol")}"
  deregistration_delay = "${lookup(var.nlb_tg_map[element(local.tg_keys,count.index)],"dereg_delay")}"
  target_type          = "${lookup(var.nlb_tg_map[element(local.tg_keys,count.index)],"target_type")}"

  health_check {
    protocol            = "${lookup(var.nlb_hc_map[element(local.hc_keys,count.index)],"protocol")}"
    healthy_threshold   = "${lookup(var.nlb_hc_map[element(local.hc_keys,count.index)],"healthy_threshold")}"
    unhealthy_threshold = "${lookup(var.nlb_hc_map[element(local.hc_keys,count.index)],"unhealthy_threshold")}"
    interval            = "${lookup(var.nlb_hc_map[element(local.hc_keys,count.index)],"interval")}"
  }
}

resource "aws_lb_listener" "nlb_listener" {
  count = "${length(local.lm_keys)}"

  load_balancer_arn = "${aws_lb.nlb.arn}"
  port              = "${lookup(var.nlb_listener_map[element(local.lm_keys,count.index)],"port")}"
  protocol          = "${lookup(var.nlb_listener_map[element(local.lm_keys,count.index)],"protocol")}"

  default_action {
    target_group_arn = "${aws_lb_target_group.nlb_tg.*.arn[count.index]}"
    type             = "forward"
  }
}

resource "aws_s3_bucket" "nlb_log_bucket" {
  # should we create a bucket or use the one provided?
  count = "${var.nlb_al_bucket == "__UNSET__" ? 1:0}"

  bucket        = "${var.nlb_name}-${var.environment}-${random_id.random_string.hex}-nlb-logs"
  force_destroy = "${var.force_destroy_log_bucket}"

  policy = "${data.aws_iam_policy_document.nlb_log_bucket_policy.json}"
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

  evaluation_periods = "${var.nlb_unhealthy_hosts_alarm_evaluation_periods}"
  metric_name        = "UnHealthyHostCount"
  namespace          = "AWS/NetworkELB"

  ok_actions = [
    "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rackspace-support-emergency",
  ]

  period    = "${var.nlb_unhealthy_hosts_alarm_period}"
  statistic = "Average"
  threshold = "${var.nlb_unhealthy_hosts_alarm_threshold}"
  unit      = "Count"

}
