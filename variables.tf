# Label: name for this load balancer
variable "nlb_name" {
  type = "string"
}

# Label: environment name e.g. dev; prod
variable environment {
  type    = "string"
  default = "test"
}

# Route53: the zone_id in which to create our CNAME
variable "route53_zone_id" {
  type    = "string"
  default = "__UNSET__"
}

# VPC: list of subnet ids (1 per AZ only) to attach to this NLB
variable "nlb_subnet_ids" {
  type = "list"
}

# VPC: explicitly tell terraform how many subnets to expect
variable "nlb_eni_count" {
  default = "0"
}

# VPC: VPC ID
variable "vpc_id" {
  type = "string"
}

# VPC: **not implemented** subnet -> EIP mapping
variable "nlb_subnet_map" {
  type = "map"

  default = {
    "0" = ["eip-1", "subnet-1"]
  }
}

# NLB: is this load-balancer "internal" or "external"? 
variable "nlb_facing" {
  default = "external"
}

# NLB: configure cross zone load balancing
variable "nlb_cross_zone" {
  default = true
}

# Label: tags map
variable "nlb_tags" {
  type = "map"

  default = {}
}

/*  NLB: listener map

e.g.
nlb_listener_map = {
  "0" = {
    "port"            = "80"
    "target_group"    = "arn:aws:elasticloadbalancing:xxxxxxx" # optionally specify existing TG ARN
  }
}
*/
variable "nlb_listener_map" {
  type = "map"
}

/*
  NLB: target group map

e.g.
nlb_tg_map  = {
  "listener1" = {
    "name"          = "listener1-tg-name"
    "port"          = "80"
    "dereg_delay"   = "300"
    "target_type"   = "instance"
  }
}
*/
variable "nlb_tg_map" {
  type = "map"
}

/* NLB: tg health checks
e.g.
nlb_hc_map  = {
  "listener1" = {
      protocol            = "TCP"
      healthy_threshold   = "3"
      unhealthy_threshold = "3"
      interval            = "30"
    }
  "listener2" = {
      protocol            = "HTTP"
      healthy_threshold   = "3"
      unhealthy_threshold = "3"
      interval            = "30"
      matcher             = "200-399"
      path                = "/"
    }
}
*/
variable "nlb_hc_map" {
  type = "map"
}

variable "enable_cloudwatch_alarm_actions" {
  type    = "string"
  default = "false"
}
