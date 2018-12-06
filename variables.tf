# Label: name for this load balancer
variable "name" {
  type = "string"
}

# Label: environment name e.g. dev; prod
variable environment {
  type    = "string"
  default = "test"
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

# Route53: the zone_id in which to create our ALIAS
variable "route_53_hosted_zone_id" {
  type    = "string"
  default = ""
}

# VPC: list of subnet ids (1 per AZ only) to attach to this NLB
variable "subnet_ids" {
  type = "list"
}

# VPC: explicitly tell terraform how many subnets to expect
variable "eni_count" {
  default = "0"
}

# VPC: VPC ID
variable "vpc_id" {
  type = "string"
}

# VPC: **not implemented** subnet -> EIP mapping
variable "subnet_map" {
  type = "map"

  default = {
    "0" = ["eip-1", "subnet-1"]
  }
}

# NLB: is this load-balancer "internal" or "external"?
variable "facing" {
  default = "external"
}

# NLB: configure cross zone load balancing
variable "cross_zone" {
  default = true
}

# Label: tags map
variable "tags" {
  type = "map"

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
  type = "map"
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
  type = "map"
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
  type = "map"
}

variable "enable_cloudwatch_alarm_actions" {
  type    = "string"
  default = "false"
}
