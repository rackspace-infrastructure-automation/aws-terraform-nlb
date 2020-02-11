terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = "~> 2.1"
}

module "nlb" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-nlb.git?ref=v0.0.6"

  enable_cloudwatch_alarm_actions = true
  environment                     = "Test"

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

  listener_map_count = 2

  listener_map = {
    listener1 = {
      port = 80
    }
    listener2 = {
      certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      port            = 443
      protocol        = "TLS"
    }
  }

  name       = "MyNLB"
  subnet_ids = ["subnet-xxxxxxxxxxxxxxxx", "subnet-xxxxxxxxxxxxxxxx"]

  tags = {
    "role"    = "load-balancer"
    "contact" = "someone@somewhere.com"
  }

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

  vpc_id = "vpc-xxxxxxxxxxxxxxxx"
}

