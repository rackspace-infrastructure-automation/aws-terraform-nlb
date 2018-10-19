# Label: name for this load balancer
variable "nlb_name" {
  type = "string"
}

# Label: environment name e.g. dev; prod
variable environment {
  type    = "string"
  default = "noenv"
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
  default = "internal"
}

# NLB: idle timeout in seconds, not currently valid for LB type "network"
variable "nlb_idle_timeout" {
  default = 60
}

# NLB: configure cross zone load balancing
variable "nlb_cross_zone" {
  default = true
}

# Label: tags map
variable "nlb_tags" {
  type = "map"

  default = {
    "nlb" = true
  }
}

# NLB: EC2 Instance list to add to target groups
variable "nlb_tg_instances" {
  type    = "list"
  default = []
}

# S3: Access Logs Bucket
variable "nlb_al_bucket" {
  default = "__UNSET__"
}

# S3: A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable.
variable "force_destroy_log_bucket" {
  default = false
}

/*  NLB: listener map

e.g.
nlb_listener_map = {
  "0" = {
    "port"            = "80"
    "protocol"        = "TCP"
    "target_group"    = "${aws_lb_target_group.nlb_tg.arn}"
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
    "protocol"      = "HTTP"
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
      protocol            = "TCP"
      healthy_threshold   = "3"
      unhealthy_threshold = "3"
      interval            = "30"
    }
}
*/
variable "nlb_hc_map" {
  type = "map"
}
