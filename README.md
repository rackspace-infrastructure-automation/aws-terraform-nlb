# aws-terraform-nlb

## Usage:

``` HCL
module "net_lb" {
  source      = "modules/network_load_balancer"
  nlb_name    = "${var.name}-internal"
  environment = "${var.environment}"
  vpc_id      = "${module.base_network.vpc_id}"
  nlb_facing  = "internal"

  nlb_subnet_ids = "${module.base_network.public_subnets}"

  # tell terraform how many to expect
  nlb_eni_count = "${length(var.private_subnets)}"
  
  nlb_listener_map         = "${var.nlb_listener_map}"
  nlb_tg_map               = "${var.nlb_tg_map}"
  nlb_hc_map               = "${var.nlb_hc_map}"
  force_destroy_log_bucket = "${var.force_destroy_log_bucket}"

  nlb_tags = "${merge(local.full_tags["internal_nlb"], local.full_tags["default_tags"])}"
```
