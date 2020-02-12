terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = "~> 2.20"
}

module "nlb" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-nlb.git?ref=v0.12.0"

  enable_cloudwatch_alarm_actions = true
  environment                     = "Test"

  hc_map = {
    listener1 = {
      protocol            = "TCP"
      healthy_threshold   = 3
      unhealthy_threshold = 3
      interval            = 30
    }
  }

  listener_map_count = 1

  listener_map = {
    listener1 = {
      port     = 25
      protocol = "UDP"
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
      protocol    = "UDP"
      dereg_delay = 300
      target_type = "instance"
    }
  }

  vpc_id = "vpc-xxxxxxxxxxxxxxxx"
}

