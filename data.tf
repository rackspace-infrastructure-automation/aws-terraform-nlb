# Determine NLB AWS Account ID for bucket policy: https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html#attach-bucket-policy
data "aws_elb_service_account" "svc_acct" {
}

data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}

data "aws_network_interface" "eni" {
  # this data source does not permit muliple results

  # Allow for a static value for eni_count
  count = var.eni_count

  filter {
    name = "description"

    values = [
      "ELB net/${aws_lb.nlb.name}/*",
    ]
  }

  filter {
    name = "subnet-id"

    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibility in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    values = [
      element(var.subnet_ids, count.index),
    ]
  }

  # terraform has no way of determining this dependency unaided
  depends_on = [aws_lb.nlb]
}

/*
# Error: data.aws_network_interfaces.enis: Provider doesn't support data source: aws_network_interfaces
# and yet: https://www.terraform.io/docs/providers/aws/d/network_interfaces.html

data "aws_network_interfaces" "enis" {
  filter {
    name = "description"

    values = [
      "ELB net/${var.name}/*",
    ]
  }
  depends_on = ["aws_lb.nlb"]
}
*/
