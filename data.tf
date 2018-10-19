# Determine NLB AWS Account ID for bucket policy: https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html#attach-bucket-policy 
data "aws_elb_service_account" "nlb_svc_acct" {}

resource "random_id" "random_string" {
  byte_length = 8

  keepers {
    name = "${var.nlb_name}"
  }
}

data "aws_network_interface" "nlb_eni" {
  # this data source does not permit muliple results

  # Allow for a static value for nlb_eni_count
  count = "${var.nlb_eni_count > 0 ? "${var.nlb_eni_count}" : length(var.nlb_subnet_ids)}"

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

data "aws_iam_policy_document" "nlb_log_bucket_policy" {
  # only generate this policy if we are going to create the bucket
  count = "${var.nlb_al_bucket == "__UNSET__" ? 1:0}"

  statement {
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${var.nlb_name}-${var.environment}-${random_id.random_string.hex}-nlb-logs/AWSLogs/*"]
    effect    = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["${data.aws_elb_service_account.nlb_svc_acct.arn}"]
    }
  }
}

data "aws_route53_zone" "provided" {
  count   = "${var.route53_zone_id == "__UNSET__" ? 0:1}"
  zone_id = "${var.route53_zone_id}"
}

