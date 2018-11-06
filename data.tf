# Determine NLB AWS Account ID for bucket policy: https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html#attach-bucket-policy
data "aws_elb_service_account" "nlb_svc_acct" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "random_id" "random_string" {
  byte_length = 8

  keepers {
    name = "${var.nlb_name}"
  }
}

data "aws_network_interface" "nlb_eni" {
  # this data source does not permit muliple results

  # Allow for a static value for nlb_eni_count
  count = "${var.nlb_eni_count}"

  filter {
    name = "description"

    values = [
      "ELB net/${var.nlb_name}/*",
    ]
  }

  filter {
    name = "subnet-id"

    values = [
      "${element(var.nlb_subnet_ids,count.index)}",
    ]
  }

  # terraform has no way of determining this dependency unaided
  depends_on = ["aws_lb.nlb"]
}

/*
# Error: data.aws_network_interfaces.nlb_enis: Provider doesn't support data source: aws_network_interfaces
# and yet: https://www.terraform.io/docs/providers/aws/d/network_interfaces.html

data "aws_network_interfaces" "nlb_enis" {
  filter {
    name = "description"

    values = [
      "ELB net/${var.nlb_name}/*",
    ]
  }
  depends_on = ["aws_lb.nlb"]
}
*/

data "aws_route53_zone" "provided" {
  count   = "${var.route53_zone_id == "__UNSET__" ? 0:1}"
  zone_id = "${var.route53_zone_id}"
}
