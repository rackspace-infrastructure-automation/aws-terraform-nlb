variable "create_internal_zone_record" {
  description = "Create Route 53 internal zone record for the NLB. i.e true | false"
  type        = bool
  default     = false
}

variable "create_logging_bucket" {
  description = "Create a new S3 logging bucket. i.e. true | false"
  type        = bool
  default     = false
}

variable "cross_zone" {
  description = "configure cross zone load balancing"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer. Defaults to false."
  type        = bool
  default     = false
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
      port                = "80"
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

variable "kms_key_id" {
  description = "The AWS KMS master key ID used for the SSE-KMS encryption. This can only be used when you set the value of sse_algorithm as aws:kms."
  type        = string
  default     = ""
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

variable "logging_bucket_acl" {
  description = "Define ACL for Bucket. Must be either authenticated-read, aws-exec-read, log-delivery-write, private, public-read or public-read-write. Via https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#canned-acl"
  type        = string
  default     = "private"
}

variable "logging_bucket_encyption" {
  description = "Enable default bucket encryption. i.e. AES256 | aws:kms"
  type        = string
  default     = "AES256"
}

variable "logging_bucket_force_destroy" {
  description = "Whether all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable. ie. true | false"
  type        = bool
  default     = false
}

variable "logging_bucket_name" {
  description = "The name of the S3 bucket for the access logs. The bucket name can contain only lowercase letters, numbers, periods (.), and dashes (-). If creating a new logging bucket enter desired bucket name."
  type        = string
  default     = ""
}

variable "logging_bucket_prefix" {
  description = "The prefix for the location in the S3 bucket. If you don't specify a prefix, the access logs are stored in the root of the bucket. Entry must not start with a / or end with one. i.e. 'logs' or 'data/logs'"
  type        = string
  default     = null
}

variable "logging_bucket_retention" {
  description = "The number of days to retain load balancer logs.  Parameter is ignored if not creating a new S3 bucket. i.e. between 1 - 999"
  type        = number
  default     = 14
}

variable "logging_enabled" {
  description = "Whether logging for this bucket is enabled."
  type        = bool
  default     = false
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

variable "public_subnet_ids" {
  description = "list of subnet ids (1 per AZ only) to attach to this NLB"
  type        = list(string)
}

variable "subnet_map_test" {
  description = "subnet -> EIP mapping"
  type        = map(list(string))

  default = {
    "0" = ["eip-1", "subnet-1"]
  }
}

variable "attach_eip_to_lb" {
  description = "Whether eip should be attached to lb"
  type        = bool
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

N.B. if you receive an error `Network Load Balancers do not support Stickiness` then try adding a key to your problem target groups of `stickiness_placeholder = true`
*/
variable "tg_map" {
  description = "target group map"
  type        = map(map(string))
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}
