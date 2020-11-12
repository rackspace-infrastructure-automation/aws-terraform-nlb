terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region  = "us-west-2"
  version = "~> 2.20"
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

  tags_count = length(keys(local.tags))
}

data "null_data_source" "asg_tags" {
  count = local.tags_count

  inputs = {
    key                 = element(keys(local.tags), count.index)
    value               = element(values(local.tags), count.index)
    propagate_at_launch = true
  }
}

resource "tls_private_key" "self" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "self" {
  key_algorithm         = "RSA"
  private_key_pem       = tls_private_key.self.private_key_pem
  validity_period_hours = 2160

  subject {
    common_name         = "self.rackspace-testing.com"
    organization        = "Rackspace"
    organizational_unit = "Partner Cloud"
  }

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "self" {
  certificate_body = tls_self_signed_cert.self.cert_pem
  private_key      = tls_private_key.self.private_key_pem

  tags = local.tags
}

resource "random_string" "rstring" {
  length  = 8
  special = false
  upper   = false
}

module "vpc" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork?ref=master"

  az_count            = 2
  cidr_range          = "10.0.0.0/16"
  name                = "${random_string.rstring.result}-test"
  private_cidr_ranges = ["10.0.2.0/24", "10.0.4.0/24"]
  public_cidr_ranges  = ["10.0.1.0/24", "10.0.3.0/24"]
  tags                = local.tags
}

module "external" {
  source = "../../module"

  create_logging_bucket = true
  eni_count             = 2

  hc_map = {
    listener1 = {
      healthy_threshold   = 3
      interval            = 30
      protocol            = "TCP"
      unhealthy_threshold = 3
    }
  }

  listener_map = {
    listener1 = {
      port = 80
    }
    listener2 = {
      certificate_arn = aws_acm_certificate.self.arn
      port            = 443
      protocol        = "TLS"
    }
  }

  listener_map_count           = 1
  logging_bucket_force_destroy = true
  logging_bucket_name          = "7893478934789789345678454-test-12342134"
  logging_enabled              = true
  name                         = "${random_string.rstring.result}-nlb-ext"
  subnet_ids                   = module.vpc.public_subnets
  tags                         = local.tags

  tg_map = {
    listener1 = {
      dereg_delay            = 300
      port                   = 80
      target_type            = "instance"
      stickiness_placeholder = true
    }
  }

  vpc_id = module.vpc.vpc_id
}

resource "random_string" "random_zone" {
  length  = 6
  lower   = true
  number  = false
  special = false
  upper   = false
}

resource "aws_route53_zone" "private" {
  force_destroy = true
  name          = "${random_string.random_zone.result}.com"

  vpc {
    vpc_id = module.vpc.vpc_id
  }

  tags = local.tags
}

module "internal" {
  source = "../../module"

  create_internal_zone_record = true
  eni_count                   = 2
  facing                      = "internal"

  hc_map = {
    listener1 = {
      healthy_threshold   = 3
      interval            = 30
      matcher             = "200-399"
      path                = "/"
      protocol            = "HTTP"
      unhealthy_threshold = 3
    }
  }

  internal_record_name = "nlb.${aws_route53_zone.private.name}"

  listener_map = {
    listener1 = {
      port = 80
    }
  }

  name                    = "${random_string.rstring.result}-nlb-int"
  route_53_hosted_zone_id = aws_route53_zone.private.zone_id
  subnet_ids              = module.vpc.private_subnets
  tags                    = local.tags

  tg_map = {
    listener1 = {
      dereg_delay            = 300
      port                   = 80
      target_type            = "instance"
      stickiness_placeholder = true
    }
  }

  vpc_id = module.vpc.vpc_id
}

module "security_groups" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-security_group?ref=master"

  name   = "ASGIR-${random_string.rstring.result}"
  vpc_id = module.vpc.vpc_id
}

module "asg" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-ec2_asg?ref=master"

  additional_tags = data.null_data_source.asg_tags.*.outputs
  ec2_os          = "amazon2"
  image_id        = data.aws_ami.amz_linux_2.image_id
  instance_type   = "t2.micro"
  name            = "${random_string.rstring.result}-test-asg"
  security_groups = [module.security_groups.public_web_security_group_id]
  scaling_max     = 2
  scaling_min     = 1
  subnets         = [element(module.vpc.public_subnets, 0), element(module.vpc.public_subnets, 1)]
  target_group_arns = concat(
    module.external.target_group_arns,
    module.internal.target_group_arns,
  )
}
