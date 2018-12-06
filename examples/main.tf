module "nlb" {
  source      = "git@github.com:rackspace-infrastructure-automation/aws-terraform-nlb.git?ref=<git tag, branch, or commit hash here>"
  environment = "Test"
  name        = "MyNLB"
  vpc_id      = "vpc-xxxxxxxxxxxxxxxx"
  subnet_ids  = ["subnet-xxxxxxxxxxxxxxxx", "subnet-xxxxxxxxxxxxxxxx"]

  # enable alarm actions for TG alarms. vars available for these parameters
  enable_cloudwatch_alarm_actions = "true"

  tags = {
    "role"    = "load-balancer"
    "contact" = "someone@somewhere.com"
  }

  listener_map = {
    listener1 = {
      port = 80
    }

    listener2 = {
      port = 8080
    }
  }

  # if `name` is not defined, then the map index is used for this value
  tg_map = {
    listener1 = {
      name        = "listener1-tg-name"
      port        = 80
      dereg_delay = 300
      target_type = "instance"
    }

    listener2 = {
      name        = "listener2-tg-name"
      port        = 8080
      dereg_delay = 300
      target_type = "instance"
    }
  }

  hc_map = {
    listener1 = {
      protocol            = "TCP"
      healthy_threshold   = 3
      unhealthy_threshold = 3
      interval            = 30
    }

    listener2 = {
      protocol            = "HTTP"
      healthy_threshold   = 3
      unhealthy_threshold = 3
      interval            = 30
      matcher             = "200-399"
      path                = "/"
    }
  }
}
