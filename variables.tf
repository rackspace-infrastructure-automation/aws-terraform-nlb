variable "name" {
  type        = "string"
  description = "name for this load balancer"
}

variable "environment" {
  type        = "string"
  default     = "test"
  description = "environment name e.g. dev; prod"
}

variable "create_internal_zone_record" {
  description = "Create Route 53 internal zone record for the NLB. i.e true | false"
  type        = "string"
  default     = false
}

variable "internal_record_name" {
  description = "Record Name for the new Resource Record in the Internal Hosted Zone. i.e. nlb.example.com"
  type        = "string"
  default     = ""
}

variable "route_53_hosted_zone_id" {
  type        = "string"
  default     = ""
  description = "the zone_id in which to create our ALIAS"
}

variable "subnet_ids" {
  type        = "list"
  description = "list of subnet ids (1 per AZ only) to attach to this NLB"
}

variable "eni_count" {
  default     = "0"
  type        = "string"
  description = "explicitly tell terraform how many subnets to expect"
}

variable "vpc_id" {
  type        = "string"
  description = "VPC ID"
}

variable "subnet_map" {
  type        = "map"
  description = "**not implemented** subnet -> EIP mapping"

  default = {
    "0" = ["eip-1", "subnet-1"]
  }
}

variable "facing" {
  default     = "external"
  type        = "string"
  description = "is this load-balancer internal or external?"
}

variable "cross_zone" {
  default     = true
  type        = "string"
  description = "configure cross zone load balancing"
}

variable "tags" {
  type        = "map"
  description = "tags map"

  default = {}
}

/*  NLB: listener map

e.g.
listener_map = {
  "0" = {
    "port"            = "80"
    "target_group"    = "arn:aws:elasticloadbalancing:xxxxxxx" # optionally specify existing TG ARN
  }
}
*/
variable "listener_map" {
  type        = "map"
  description = "listener map"
}

/*
  NLB: target group map

e.g.
tg_map  = {
  "listener1" = {
    "name"          = "listener1-tg-name"
    "port"          = "80"
    "dereg_delay"   = "300"
    "target_type"   = "instance"
  }
}
*/
variable "tg_map" {
  type        = "map"
  description = "target group map"
}

/* NLB: tg health checks
e.g.
hc_map  = {
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
variable "hc_map" {
  type        = "map"
  description = "health check map"
}

variable "enable_cloudwatch_alarm_actions" {
  type        = "string"
  default     = "false"
  description = "enable cloudwatch alarm actions true or false"
}
