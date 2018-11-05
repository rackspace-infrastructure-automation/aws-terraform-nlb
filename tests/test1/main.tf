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
  source              = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork//?ref=master"
  az_count            = 2
  cidr_range          = "10.0.0.0/16"
  public_cidr_ranges  = ["10.0.1.0/24", "10.0.3.0/24"]
  private_cidr_ranges = ["10.0.2.0/24", "10.0.4.0/24"]
  vpc_name            = "${random_string.rstring.result}-test"
}

module "nlb_external" {
  source = "../../module"

  nlb_name       = "${random_string.rstring.result}-test-nlb"
  vpc_id         = "${module.vpc.vpc_id}"
  nlb_subnet_ids = "${module.vpc.public_subnets}"
  nlb_eni_count  = 2

  nlb_listener_map = {
    listener1 = {
      port = 80
    }
  }

  nlb_tg_map = {
    listener1 = {
      port        = 80
      dereg_delay = 300
      target_type = "instance"
    }
  }

  nlb_hc_map = {
    listener1 = {
      protocol            = "TCP"
      healthy_threshold   = 3
      unhealthy_threshold = 3
      interval            = 30
    }
  }
}

module "nlb_internal" {
  source = "../../module"

  nlb_name       = "${random_string.rstring.result}-test-nlb"
  vpc_id         = "${module.vpc.vpc_id}"
  nlb_subnet_ids = "${module.vpc.private_subnets}"
  nlb_eni_count  = 2
  nlb_facing     = "internal"

  nlb_listener_map = {
    listener1 = {
      port = 80
    }
  }

  nlb_tg_map = {
    listener1 = {
      port        = 80
      dereg_delay = 300
      target_type = "instance"
    }
  }

  nlb_hc_map = {
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
  source        = "git@github.com:rackspace-infrastructure-automation/aws-terraform-security_group//?ref=master"
  resource_name = "ASGIR-${random_string.rstring.result}"
  vpc_id        = "${module.vpc.vpc_id}"
}

module "asg" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-ec2_asg//?ref=master"

  ec2_os              = "amazon"
  image_id            = "${data.aws_ami.amz_linux_2.image_id}"
  instance_type       = "t2.micro"
  resource_name       = "${random_string.rstring.result}-test-asg"
  security_group_list = ["${module.security_groups.public_web_security_group_id}"]
  scaling_max         = "2"
  scaling_min         = "1"
  subnets             = ["${element(module.vpc.public_subnets, 0)}", "${element(module.vpc.public_subnets, 1)}"]
  target_group_arns   = ["${concat(module.nlb_external.target_group_arns, module.nlb_internal.target_group_arns)}"]
}
