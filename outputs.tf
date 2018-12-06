/*
### Outputs section for the NLB module

For consistency, it is intended to mimic as far as applicable the [community ALB module](https://github.com/terraform-aws-modules/terraform-aws-alb/blob/master/outputs.tf)
[Parent module](https://github.com/terraform-aws-modules/terraform-aws-alb)

*/

# output: the DNS name of the load balancer
output "dns_name" {
  value = "${aws_lb.nlb.dns_name}"
}

# output: the ID and ARN of the load balancer
output "load_balancer_id" {
  value = "${aws_lb.nlb.id}"
}

# output: The canonical hosted zone ID of the load balancer (to be used in a Route 53 Alias record).
output "load_balancer_zone_id" {
  value = "${aws_lb.nlb.zone_id}"
}

# output: The ARN suffix for use with CloudWatch Metrics.
output "load_balancer_arn_suffix" {
  value = "${aws_lb.nlb.arn_suffix}"
}

# NLB: ARNs of the target groups. Useful for passing to your Auto Scaling group.
output "target_group_arns" {
  value = "${flatten(aws_lb_target_group.tg.*.arn)}"
}

# NLB: ARN suffixes of our target groups - can be used with CloudWatch.
output "target_group_arn_suffixes" {
  value = "${flatten(aws_lb_target_group.tg.*.arn_suffix)}"
}

# NLB: Name of the target group. Useful for passing to your CodeDeploy Deployment Group
output "target_group_names" {
  value = "${flatten(aws_lb_target_group.tg.*.name)}"
}

# NLB: the private IPs of this LB for use in EC2 security groups
output "eni_ips" {
  value = "${flatten(data.aws_network_interface.eni.*.private_ips)}"
}
