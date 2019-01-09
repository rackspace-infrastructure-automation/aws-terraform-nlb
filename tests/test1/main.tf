provider "aws" {
  version = "~> 1.2"
  region  = "us-west-2"
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

resource "random_string" "rstring" {
  length  = 8
  upper   = false
  special = false
}

module "vpc" {
  source              = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork?ref=master"
  az_count            = 2
  cidr_range          = "10.0.0.0/16"
  public_cidr_ranges  = ["10.0.1.0/24", "10.0.3.0/24"]
  private_cidr_ranges = ["10.0.2.0/24", "10.0.4.0/24"]
  vpc_name            = "${random_string.rstring.result}-test"
}

module "external" {
  source = "../../module"

  name       = "${random_string.rstring.result}-nlb-ext"
  vpc_id     = "${module.vpc.vpc_id}"
  subnet_ids = "${module.vpc.public_subnets}"
  eni_count  = 2

  listener_map = {
    listener1 = {
      port = 80
    }
  }

  tg_map = {
    listener1 = {
      port        = 80
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
  }
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
}

module "internal" {
  source = "../../module"

  name                        = "${random_string.rstring.result}-nlb-int"
  vpc_id                      = "${module.vpc.vpc_id}"
  subnet_ids                  = "${module.vpc.private_subnets}"
  eni_count                   = 2
  facing                      = "internal"
  create_internal_zone_record = true
  route_53_hosted_zone_id     = "${aws_route53_zone.private.zone_id}"
  internal_record_name        = "nlb.${aws_route53_zone.private.name}"

  listener_map = {
    listener1 = {
      port = 80
    }
  }

  tg_map = {
    listener1 = {
      port        = 80
      dereg_delay = 300
      target_type = "instance"
    }
  }

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
}

module "security_groups" {
  source        = "git@github.com:rackspace-infrastructure-automation/aws-terraform-security_group?ref=master"
  resource_name = "ASGIR-${random_string.rstring.result}"
  vpc_id        = "${module.vpc.vpc_id}"
}

module "asg" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-ec2_asg?ref=master"

  ec2_os              = "amazon"
  image_id            = "${data.aws_ami.amz_linux_2.image_id}"
  instance_type       = "t2.micro"
  resource_name       = "${random_string.rstring.result}-test-asg"
  security_group_list = ["${module.security_groups.public_web_security_group_id}"]
  scaling_max         = "2"
  scaling_min         = "1"
  subnets             = ["${element(module.vpc.public_subnets, 0)}", "${element(module.vpc.public_subnets, 1)}"]
  target_group_arns   = ["${concat(module.external.target_group_arns, module.internal.target_group_arns)}"]
}
