provider "aws" {
  version = "~> 2.20"
  region  = "us-west-2"
}

provider "null" {
  version = "~> 2.0"
}

provider "random" {
  version = "~> 2.0"
}

provider "tls" {
  version = "~> 2.0"
}

data "aws_ami" "amz_linux_2" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

locals {
  tags = {
    Environment     = "Test"
    Purpose         = "Testing aws-terraform-nlb"
    ServiceProvider = "Rackspace"
    Terraform       = "true"
  }

  tags_count = "${length(keys(local.tags))}"
}

data "null_data_source" "asg_tags" {
  count = "${local.tags_count}"

  inputs = {
    key                 = "${element(keys(local.tags), count.index)}"
    value               = "${element(values(local.tags), count.index)}"
    propagate_at_launch = true
  }
}

resource "tls_private_key" "self" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "self" {
  key_algorithm         = "RSA"
  private_key_pem       = "${tls_private_key.self.private_key_pem}"
  validity_period_hours = 2160

  subject {
    common_name         = "self.rackspace-testing.com"
    organization        = "Rackspace"
    organizational_unit = "Partner Cloud"
  }

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "self" {
  private_key      = "${tls_private_key.self.private_key_pem}"
  certificate_body = "${tls_self_signed_cert.self.cert_pem}"

  tags = "${local.tags}"
}

resource "random_string" "rstring" {
  length  = 8
  upper   = false
  special = false
}

module "vpc" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork?ref=master"

  az_count            = 2
  cidr_range          = "10.0.0.0/16"
  custom_tags         = "${local.tags}"
  public_cidr_ranges  = ["10.0.1.0/24", "10.0.3.0/24"]
  private_cidr_ranges = ["10.0.2.0/24", "10.0.4.0/24"]
  vpc_name            = "${random_string.rstring.result}-test"
}

module "external" {
  source = "../../module"

  eni_count = 2

  hc_map = {
    listener1 = {
      protocol            = "TCP"
      healthy_threshold   = 3
      unhealthy_threshold = 3
      interval            = 30
    }

    listener2 = {
      protocol            = "TCP"
      healthy_threshold   = 3
      unhealthy_threshold = 3
      interval            = 30
    }

    listener3 = {
      protocol            = "TCP"
      healthy_threshold   = 3
      unhealthy_threshold = 3
      interval            = 30
    }
  }

  listener_map = {
    listener1 = {
      port = 80
    }

    listener2 = {
      certificate_arn = "${aws_acm_certificate.self.arn}"
      port            = 443
      protocol        = "TLS"
    }

    listener3 = {
      port     = 53
      protocol = "UDP"
    }
  }

  listener_map_count = 3
  name               = "${random_string.rstring.result}-nlb-ext"
  subnet_ids         = "${module.vpc.public_subnets}"
  tags               = "${local.tags}"

  tg_map = {
    listener1 = {
      dereg_delay = 300
      port        = 80
      target_type = "instance"
    }

    listener2 = {
      dereg_delay = 300
      port        = 443
      target_type = "instance"
    }

    listener3 = {
      dereg_delay = 300
      port        = 53
      protocol    = "UDP"
      target_type = "instance"
    }
  }

  vpc_id = "${module.vpc.vpc_id}"
}

resource "random_string" "random_zone" {
  length  = 6
  upper   = false
  lower   = true
  special = false
  number  = false
}

resource "aws_route53_zone" "private" {
  name          = "${random_string.random_zone.result}.com"
  force_destroy = true

  vpc {
    vpc_id = "${module.vpc.vpc_id}"
  }

  tags = "${local.tags}"
}

module "internal" {
  source = "../../module"

  create_internal_zone_record = true
  eni_count                   = 2
  facing                      = "internal"

  hc_map = {
    listener1 = {
      protocol            = "HTTP"
      healthy_threshold   = 3
      unhealthy_threshold = 3
      interval            = 30
      matcher             = "200-399"
      path                = "/"
    }
  }

  internal_record_name = "nlb.${aws_route53_zone.private.name}"

  listener_map = {
    listener1 = {
      port = 80
    }
  }

  name                    = "${random_string.rstring.result}-nlb-int"
  route_53_hosted_zone_id = "${aws_route53_zone.private.zone_id}"
  subnet_ids              = "${module.vpc.private_subnets}"
  tags                    = "${local.tags}"

  tg_map = {
    listener1 = {
      port        = 80
      dereg_delay = 300
      target_type = "instance"
    }
  }

  vpc_id = "${module.vpc.vpc_id}"
}

module "security_groups" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-security_group?ref=master"

  resource_name = "ASGIR-${random_string.rstring.result}"
  vpc_id        = "${module.vpc.vpc_id}"
}

module "asg" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-ec2_asg?ref=master"

  additional_tags     = "${data.null_data_source.asg_tags.*.outputs}"
  ec2_os              = "amazon2"
  image_id            = "${data.aws_ami.amz_linux_2.image_id}"
  instance_type       = "t2.micro"
  resource_name       = "${random_string.rstring.result}-test-asg"
  security_group_list = ["${module.security_groups.public_web_security_group_id}"]
  scaling_max         = 2
  scaling_min         = 1
  subnets             = ["${element(module.vpc.public_subnets, 0)}", "${element(module.vpc.public_subnets, 1)}"]
  target_group_arns   = ["${concat(module.external.target_group_arns, module.internal.target_group_arns)}"]
}
