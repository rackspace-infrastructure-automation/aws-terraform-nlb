# aws-terraform-nlb

This module provides the functionality to deploy a Network Load Balancer complete with listeners and target groups.

## Usage:

This and other examples available [here](examples/)

```HCL
module "nlb" {
  source         = "git@github.com:rackspace-infrastructure-automation/aws-terraform-nlb.git//?ref=v0.12.2"

  # enable alarm actions for TG alarms. vars available for these parameters
  enable_cloudwatch_alarm_actions = true
  environment                     = "Test"

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

   listener_map_count = 2

  listener_map = {
    listener1 = {
      port = 80
    }

    listener2 = {
      certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      port            = 443
      protocol        = "TLS"
    }
  }

  name       = "MyNLB"
  subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-xxxxxxxxxxxxxxxxx"]
  vpc_id     = "vpc-xxxxxxxxxxxxxxxxx"

  tags = {
    "role"    = "load-balancer"
    "contact" = "someone@somewhere.com"
  }

  # if `name` is not defined, then the map index is used for this value
  tg_map = {
    listener1 = {
      name        = "listener1-tg-name"
      port        = 80
      dereg_delay = 300
      target_type = "instance"
    }

    listener2 = {
      name        = "listener2-tg-name"
      port        = 8080
      dereg_delay = 300
      target_type = "instance"
    }
  }
}
```

## Limitations

- Current module does not support the use of elastic IPs on the NLB at this time, due to a limitation in generating the SubnetMappings list.  This is expected to be corrected with the release of terraform v0.12.

## Other TF Modules Used

Using [aws-terraform-cloudwatch\_alarm](https://github.com/rackspace-infrastructure-automation/aws-terraform-cloudwatch_alarm) to create the following CloudWatch Alarms:
  - unhealthy\_host\_count\_alarm

## Providers

| Name | Version |
|------|---------|
| aws | >= 2.20 |
| null | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| create\_internal\_zone\_record | Create Route 53 internal zone record for the NLB. i.e true \| false | `bool` | `false` | no |
| create\_logging\_bucket | Create a new S3 logging bucket. i.e. true \| false | `bool` | `false` | no |
| cross\_zone | configure cross zone load balancing | `bool` | `true` | no |
| enable\_deletion\_protection | If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer. Defaults to false. | `bool` | `false` | no |
| eni\_count | explicitly tell terraform how many subnets to expect | `number` | `0` | no |
| environment | environment name e.g. dev; prod | `string` | `"test"` | no |
| facing | is this load-balancer internal or external? | `string` | `"external"` | no |
| hc\_map | health check map | `map(map(string))` | n/a | yes |
| internal\_record\_name | Record Name for the new Resource Record in the Internal Hosted Zone. i.e. nlb.example.com | `string` | `""` | no |
| kms\_key\_id | The AWS KMS master key ID used for the SSE-KMS encryption. This can only be used when you set the value of sse\_algorithm as aws:kms. | `string` | `""` | no |
| listener\_map | listener map | `map(map(string))` | n/a | yes |
| listener\_map\_count | The number of listener maps to utilize | `number` | `1` | no |
| logging\_bucket\_acl | Define ACL for Bucket. Must be either authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control, log-delivery-write, private, public-read or public-read-write. Via https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#canned-acl | `string` | `"bucket-owner-full-control"` | no |
| logging\_bucket\_encyption | Enable default bucket encryption. i.e. AES256 \| aws:kms | `string` | `"AES256"` | no |
| logging\_bucket\_force\_destroy | Whether all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable. ie. true \| false | `bool` | `false` | no |
| logging\_bucket\_name | The name of the S3 bucket for the access logs. The bucket name can contain only lowercase letters, numbers, periods (.), and dashes (-). If creating a new logging bucket enter desired bucket name. | `string` | `""` | no |
| logging\_bucket\_prefix | The prefix for the location in the S3 bucket. If you don't specify a prefix, the access logs are stored in the root of the bucket. Entry must not start with a / or end with one. i.e. 'logs' or 'data/logs' | `string` | n/a | yes |
| logging\_bucket\_retention | The number of days to retain load balancer logs.  Parameter is ignored if not creating a new S3 bucket. i.e. between 1 - 999 | `number` | `14` | no |
| logging\_enabled | Whether logging for this bucket is enabled. | `bool` | `false` | no |
| name | name for this load balancer | `string` | n/a | yes |
| notification\_topic | List of SNS Topic ARNs to use for customer notifications. | `list(string)` | `[]` | no |
| rackspace\_alarms\_enabled | Specifies whether alarms will create a Rackspace ticket.  Ignored if rackspace\_managed is set to false. | `bool` | `false` | no |
| rackspace\_managed | Boolean parameter controlling if instance will be fully managed by Rackspace support teams, created CloudWatch alarms that generate tickets, and utilize Rackspace managed SSM documents. | `bool` | `true` | no |
| route\_53\_hosted\_zone\_id | the zone\_id in which to create our ALIAS | `string` | `""` | no |
| subnet\_ids | list of subnet ids (1 per AZ only) to attach to this NLB | `list(string)` | n/a | yes |
| subnet\_map | **not implemented** subnet -> EIP mapping | `map(list(string))` | <pre>{<br>  "0": [<br>    "eip-1",<br>    "subnet-1"<br>  ]<br>}</pre> | no |
| tags | tags map | `map(string)` | `{}` | no |
| tg\_map | target group map | `map(map(string))` | n/a | yes |
| vpc\_id | VPC ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| dns\_name | the DNS name of the load balancer |
| eni\_ips | the private IPs of this LB for use in EC2 security groups |
| load\_balancer\_arn\_suffix | The ARN suffix for use with CloudWatch Metrics. |
| load\_balancer\_id | the ID and ARN of the load balancer |
| load\_balancer\_zone\_id | The canonical hosted zone ID of the load balancer (to be used in a Route 53 Alias record). |
| logging\_bucket\_arn | The ARN of the bucket. Will be of format arn:aws:s3:::bucketname. |
| logging\_bucket\_domain\_name | The bucket domain name. Will be of format bucketname.s3.amazonaws.com. |
| logging\_bucket\_hosted\_zone\_id | The Route 53 Hosted Zone ID for this bucket's region. |
| logging\_bucket\_id | The name of the bucket. |
| logging\_bucket\_region | The AWS region this bucket resides in. |
| logging\_bucket\_regional\_domain\_name | The bucket region-specific domain name. The bucket domain name including the region name. |
| target\_group\_arn\_suffixes | ARN suffixes of our target groups - can be used with CloudWatch. |
| target\_group\_arns | ARNs of the target groups. Useful for passing to your Auto Scaling group. |
| target\_group\_names | Name of the target group. Useful for passing to your CodeDeploy Deployment Group |

