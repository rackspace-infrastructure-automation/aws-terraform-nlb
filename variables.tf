variable "create_internal_zone_record" {
  description = "Create Route 53 internal zone record for the NLB. i.e true | false"
  type        = bool
  default     = false
}

variable "cross_zone" {
  description = "configure cross zone load balancing"
  type        = bool
  default     = true
}

variable "eni_count" {
  description = "explicitly tell terraform how many subnets to expect"
  type        = number
  default     = 0
}

variable "environment" {
  description = "environment name e.g. dev; prod"
  type        = string
  default     = "test"
}

variable "facing" {
  description = "is this load-balancer internal or external?"
  type        = string
  default     = "external"
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
  description = "health check map"
  type        = map(map(string))
}

variable "internal_record_name" {
  description = "Record Name for the new Resource Record in the Internal Hosted Zone. i.e. nlb.example.com"
  type        = string
  default     = ""
}

/*  NLB: listener map

e.g.
listener_map = {
  "0" = {
    "certificate_arn" = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-90ab-cdef-1234-567890abcdef>" # Required for the TLS protocol
    "port"            = "80"
    "protocol"        = "TCP" # Defaults to TCP.  Allowed values: TCP, TLS
    "ssl_protocol"    = "ELBSecurityPolicy-TLS-1-2-2017-02" # Optional, to set a specific SSL Policy.
    "target_group"    = "arn:aws:elasticloadbalancing:xxxxxxx" # optionally specify existing TG ARN
  }
}
*/
variable "listener_map" {
  description = "listener map"
  type        = map(map(string))
}

variable "listener_map_count" {
  description = "The number of listener maps to utilize"
  type        = number
  default     = 1
}

variable "name" {
  description = "name for this load balancer"
  type        = string
}

variable "notification_topic" {
  description = "List of SNS Topic ARNs to use for customer notifications."
  type        = list(string)
  default     = []
}

variable "rackspace_alarms_enabled" {
  description = "Specifies whether alarms will create a Rackspace ticket.  Ignored if rackspace_managed is set to false."
  type        = bool
  default     = false
}

variable "rackspace_managed" {
  description = "Boolean parameter controlling if instance will be fully managed by Rackspace support teams, created CloudWatch alarms that generate tickets, and utilize Rackspace managed SSM documents."
  type        = bool
  default     = true
}

variable "route_53_hosted_zone_id" {
  description = "the zone_id in which to create our ALIAS"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "list of subnet ids (1 per AZ only) to attach to this NLB"
  type        = list(string)
}

variable "subnet_map" {
  description = "**not implemented** subnet -> EIP mapping"
  type        = map(list(string))

  default = {
    "0" = ["eip-1", "subnet-1"]
  }
}

variable "tags" {
  description = "tags map"
  type        = map(string)

  default = {}
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
  description = "target group map"
  type        = map(map(string))
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}
