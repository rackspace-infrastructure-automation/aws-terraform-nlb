# aws-terraform-nlb

This module provides the functionality to deploy a Network Load Balancer complete with listeners and target groups.

## Usage:
this and other examples available [here](examples/)

```
module "nlb" {
 source         = "git@github.com:rackspace-infrastructure-automation/aws-terraform-nlb.git?ref=v0.0.3"
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
     certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
     port     = 443
     protocol = "TLS"
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
| create\_internal\_zone\_record | Create Route 53 internal zone record for the NLB. i.e true | false | string | `"false"` | no |
| cross\_zone | configure cross zone load balancing | string | `"true"` | no |
| eni\_count | explicitly tell terraform how many subnets to expect | string | `"0"` | no |
| environment | environment name e.g. dev; prod | string | `"test"` | no |
| facing | is this load-balancer internal or external? | string | `"external"` | no |
| hc\_map | health check map | map | n/a | yes |
| internal\_record\_name | Record Name for the new Resource Record in the Internal Hosted Zone. i.e. nlb.example.com | string | `""` | no |
| listener\_map | listener map | map | n/a | yes |
| name | name for this load balancer | string | n/a | yes |
| notification\_topic | List of SNS Topic ARNs to use for customer notifications. | list | `<list>` | no |
| rackspace\_alarms\_enabled | Specifies whether alarms will create a Rackspace ticket.  Ignored if rackspace_managed is set to false. | string | `"false"` | no |
| rackspace\_managed | Boolean parameter controlling if instance will be fully managed by Rackspace support teams, created CloudWatch alarms that generate tickets, and utilize Rackspace managed SSM documents. | string | `"true"` | no |
| route\_53\_hosted\_zone\_id | the zone_id in which to create our ALIAS | string | `""` | no |
| subnet\_ids | list of subnet ids (1 per AZ only) to attach to this NLB | list | n/a | yes |
| subnet\_map | **not implemented** subnet -> EIP mapping | map | `<map>` | no |
| tags | tags map | map | `<map>` | no |
| tg\_map | target group map | map | n/a | yes |
| vpc\_id | VPC ID | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| dns\_name | the DNS name of the load balancer |
| eni\_ips | the private IPs of this LB for use in EC2 security groups |
| load\_balancer\_arn\_suffix | The ARN suffix for use with CloudWatch Metrics. |
| load\_balancer\_id | the ID and ARN of the load balancer |
| load\_balancer\_zone\_id | The canonical hosted zone ID of the load balancer (to be used in a Route 53 Alias record). |
| target\_group\_arn\_suffixes | ARN suffixes of our target groups - can be used with CloudWatch. |
| target\_group\_arns | ARNs of the target groups. Useful for passing to your Auto Scaling group. |
| target\_group\_names | Name of the target group. Useful for passing to your CodeDeploy Deployment Group |

