# Determine NLB AWS Account ID for bucket policy: https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html#attach-bucket-policy
data "aws_elb_service_account" "svc_acct" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "random_id" "random_string" {
  byte_length = 8

  keepers {
    name = "${var.name}"
  }
}

data "aws_network_interface" "eni" {
  count = "${length(var.subnet_ids)}"

  filter {
    name = "description"

    values = [
      "ELB ${aws_lb.nlb.arn_suffix}",
    ]
  }

  filter {
    name = "subnet-id"

    values = [
      "${element(var.subnet_ids,count.index)}",
    ]
  }
}
