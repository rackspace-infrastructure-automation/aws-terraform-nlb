/*
### Outputs section for the NLB module

For consistency, it is intended to mimic as far as applicable the [community ALB module](https://github.com/terraform-aws-modules/terraform-aws-alb/blob/master/outputs.tf)
[Parent module](https://github.com/terraform-aws-modules/terraform-aws-alb)

*/

output "dns_name" {
  value       = aws_lb.nlb.dns_name
  description = "the DNS name of the load balancer"
}

output "eni_ips" {
  value       = flatten(data.aws_network_interface.eni.*.private_ips)
  description = "the private IPs of this LB for use in EC2 security groups"
}

output "load_balancer_arn_suffix" {
  value       = aws_lb.nlb.arn_suffix
  description = "The ARN suffix for use with CloudWatch Metrics."
}

output "load_balancer_id" {
  value       = aws_lb.nlb.id
  description = "the ID and ARN of the load balancer"
}

output "load_balancer_zone_id" {
  value       = aws_lb.nlb.zone_id
  description = "The canonical hosted zone ID of the load balancer (to be used in a Route 53 Alias record)."
}

output "logging_bucket_arn" {
  description = "The ARN of the bucket. Will be of format arn:aws:s3:::bucketname."
  value       = aws_s3_bucket.log_bucket.*.arn
}

output "logging_bucket_domain_name" {
  description = "The bucket domain name. Will be of format bucketname.s3.amazonaws.com."
  value       = aws_s3_bucket.log_bucket.*.bucket_domain_name
}

output "logging_bucket_hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for this bucket's region."
  value       = aws_s3_bucket.log_bucket.*.hosted_zone_id
}

output "logging_bucket_id" {
  description = "The name of the bucket."
  value       = aws_s3_bucket.log_bucket.*.id
}

output "logging_bucket_region" {
  description = "The AWS region this bucket resides in."
  value       = aws_s3_bucket.log_bucket.*.region
}

output "logging_bucket_regional_domain_name" {
  description = "The bucket region-specific domain name. The bucket domain name including the region name."
  value       = aws_s3_bucket.log_bucket.*.bucket_regional_domain_name
}

output "target_group_arn_suffixes" {
  value       = flatten(aws_lb_target_group.tg.*.arn_suffix)
  description = "ARN suffixes of our target groups - can be used with CloudWatch."
}

output "target_group_arns" {
  value       = flatten(aws_lb_target_group.tg.*.arn)
  description = "ARNs of the target groups. Useful for passing to your Auto Scaling group."
}

output "target_group_names" {
  value       = flatten(aws_lb_target_group.tg.*.name)
  description = "Name of the target group. Useful for passing to your CodeDeploy Deployment Group"
}
