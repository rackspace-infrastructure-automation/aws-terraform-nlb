# aws-terraform-nlb

## Usage:

``` HCL
module "net_lb" {
  source                          = "git@github.com:rackspace-infrastructure-automation/aws-terraform-nlb.git?ref=<git tag, branch, or commit hash here>"
  nlb_name                        = "${var.name}-internal"
  environment                     = "${var.environment}"
  vpc_id                          = "${module.base_network.vpc_id}"
  nlb_facing                      = "internal"

  nlb_subnet_ids                  = "${module.base_network.public_subnets}"

  # tell terraform how many to expect
  nlb_eni_count                   = "${length(var.private_subnets)}"
  
  # see variables.tf for examples
  nlb_listener_map                = "${var.nlb_listener_map}"
  nlb_tg_map                      = "${var.nlb_tg_map}"
  nlb_hc_map                      = "${var.nlb_hc_map}"
  force_destroy_log_bucket        = "${var.force_destroy_log_bucket}"

  # enable alarm actions for TG alarms. vars available for these parameters
  enable_cloudwatch_alarm_actions = "true"

  nlb_tags                        ="${merge(local.full_tags["internal_nlb"], local.full_tags["default_tags"])}"
```


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| enable_cloudwatch_alarm_actions |  | string | `false` | no |
| environment | Label: environment name e.g. dev; prod | string | `noenv` | no |
| force_destroy_log_bucket | S3: A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable. | string | `false` | no |
| nlb_al_bucket | S3: Access Logs Bucket | string | `__UNSET__` | no |
| nlb_alarm_topic | CloudWatch: SNS topic for alarm actions | string | `rackspace-support-urgent` | no |
| nlb_cross_zone | NLB: configure cross zone load balancing | string | `true` | no |
| nlb_eni_count | VPC: explicitly tell terraform how many subnets to expect | string | `0` | no |
| nlb_facing | NLB: is this load-balancer "internal" or "external"? | string | `internal` | no |
| nlb_hc_map | /* NLB: tg health checks e.g. nlb_hc_map  = {   "listener1" = {       protocol            = "TCP"       healthy_threshold   = "3"       unhealthy_threshold = "3"       interval            = "30"     }   "listener2" = {       protocol            = "TCP"       healthy_threshold   = "3"       unhealthy_threshold = "3"       interval            = "30"     } } */ | map | - | yes |
| nlb_idle_timeout | NLB: idle timeout in seconds, not currently valid for LB type "network" | string | `60` | no |
| nlb_listener_map | /*  NLB: listener map<br><br>e.g. nlb_listener_map = {   "0" = {     "port"            = "80"     "protocol"        = "TCP"     "target_group"    = "${aws_lb_target_group.nlb_tg.arn}"   } } */ | map | - | yes |
| nlb_name | Label: name for this load balancer | string | - | yes |
| nlb_subnet_ids | VPC: list of subnet ids (1 per AZ only) to attach to this NLB | list | - | yes |
| nlb_subnet_map | VPC: **not implemented** subnet -> EIP mapping | map | `<map>` | no |
| nlb_tags | Label: tags map | map | `<map>` | no |
| nlb_tg_map | /*   NLB: target group map<br><br>e.g. nlb_tg_map  = {   "listener1" = {     "name"          = "listener1-tg-name"     "port"          = "80"     "protocol"      = "HTTP"     "dereg_delay"   = "300"     "target_type"   = "instance"   } } */ | map | - | yes |
| nlb_unhealthy_hosts_alarm_evaluation_periods | CloudWatch: alarm sample count threhold | string | `2` | no |
| nlb_unhealthy_hosts_alarm_period | CloudWatch: alarm sample period in seconds | string | `60` | no |
| nlb_unhealthy_hosts_alarm_threshold | CloudWatch: number of unhealthy hosts to trigger on | string | `1` | no |
| route53_zone_id | Route53: the zone_id in which to create our CNAME | string | `__UNSET__` | no |
| vpc_id | VPC: VPC ID | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| dns_name | output: the DNS name of the load balancer |
| load_balancer_arn_suffix | output: The ARN suffix for use with CloudWatch Metrics. |
| load_balancer_id | output: the ID and ARN of the load balancer |
| load_balancer_log_bucket | output: the ID of the log bucket we are using |
| load_balancer_zone_id | output: The canonical hosted zone ID of the load balancer (to be used in a Route 53 Alias record). |
| nlb_eni_ips | NLB: the private IPs of this LB for use in EC2 security groups |
| target_group_arn_suffixes | NLB: ARN suffixes of our target groups - can be used with CloudWatch. |
| target_group_arns | NLB: ARNs of the target groups. Useful for passing to your Auto Scaling group. |
| target_group_names | NLB: Name of the target group. Useful for passing to your CodeDeploy Deployment Group |

