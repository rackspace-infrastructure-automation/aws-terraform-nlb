# aws-terraform-nlb

This module provides the functionality to deploy a Network Load Balancer complete with listeners and target groups.

## Usage:
this and other examples available [here](examples/)

```
module "nlb" {
 source         = "git@github.com:rackspace-infrastructure-automation/aws-terraform-nlb.git?ref=<git tag, branch, or commit hash here>"
 environment    = "Test"
 name       = "MyNLB"

 vpc_id = "vpc-xxxxxxxxxxxxxxxxx"
 subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-xxxxxxxxxxxxxxxxx"]

 # enable alarm actions for TG alarms. vars available for these parameters
 enable_cloudwatch_alarm_actions = "true"

 tags      = {
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
     name       = "listener1-tg-name"
     port        = 80
     dereg_delay = 300
     target_type = "instance"
   }

   listener2 = {
     name       = "listener2-tg-name"
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
```

## Limitations

- Current module does not support the use of elastic IPs on the NLB at this time, due to a limitation in generating the SubnetMappings list.  This is expected to be corrected with the release of terraform v0.12.


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| create_internal_zone_record | Create Route 53 internal zone record for the NLB. i.e true | false | string | `false` | no |
| cross_zone | NLB: configure cross zone load balancing | string | `true` | no |
| enable_cloudwatch_alarm_actions |  | string | `false` | no |
| eni_count | VPC: explicitly tell terraform how many subnets to expect | string | `0` | no |
| environment | Label: environment name e.g. dev; prod | string | `test` | no |
| facing | NLB: is this load-balancer "internal" or "external"? | string | `external` | no |
| hc_map | /* NLB: tg health checks e.g. hc_map  = {   "listener1" = {       protocol            = "TCP"       healthy_threshold   = "3"       unhealthy_threshold = "3"       interval            = "30"     }   "listener2" = {       protocol            = "HTTP"       healthy_threshold   = "3"       unhealthy_threshold = "3"       interval            = "30"       matcher             = "200-399"       path                = "/"     } } */ | map | - | yes |
| listener_map | /*  NLB: listener map<br><br>e.g. listener_map = {   "0" = {     "port"            = "80"     "target_group"    = "arn:aws:elasticloadbalancing:xxxxxxx" # optionally specify existing TG ARN   } } */ | map | - | yes |
| name | Label: name for this load balancer | string | - | yes |
| route53_internal_record_name | Record Name for the new Resource Record in the Internal Hosted Zone. i.e. nlb.example.com | string | `` | no |
| route53_zone_id | Route53: the zone_id in which to create our CNAME | string | `` | no |
| subnet_ids | VPC: list of subnet ids (1 per AZ only) to attach to this NLB | list | - | yes |
| subnet_map | VPC: **not implemented** subnet -> EIP mapping | map | `<map>` | no |
| tags | Label: tags map | map | `<map>` | no |
| tg_map | /*   NLB: target group map<br><br>e.g. tg_map  = {   "listener1" = {     "name"          = "listener1-tg-name"     "port"          = "80"     "dereg_delay"   = "300"     "target_type"   = "instance"   } } */ | map | - | yes |
| vpc_id | VPC: VPC ID | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| dns_name | output: the DNS name of the load balancer |
| eni_ips | NLB: the private IPs of this LB for use in EC2 security groups |
| load_balancer_arn_suffix | output: The ARN suffix for use with CloudWatch Metrics. |
| load_balancer_id | output: the ID and ARN of the load balancer |
| load_balancer_zone_id | output: The canonical hosted zone ID of the load balancer (to be used in a Route 53 Alias record). |
| target_group_arn_suffixes | NLB: ARN suffixes of our target groups - can be used with CloudWatch. |
| target_group_arns | NLB: ARNs of the target groups. Useful for passing to your Auto Scaling group. |
| target_group_names | NLB: Name of the target group. Useful for passing to your CodeDeploy Deployment Group |
