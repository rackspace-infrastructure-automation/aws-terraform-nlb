locals {
  default_tg_params = {
    dereg_delay = 300
    target_type = "instance"
  }

  default_health_check = {
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

  tg_keys = "${keys(var.nlb_tg_map)}"
  lm_keys = "${keys(var.nlb_listener_map)}"
  hc_keys = "${keys(var.nlb_hc_map)}"

  tags = "${merge(var.nlb_tags, map("Environment", "${var.environment}", "ServiceProvider", "Rackspace"))}"
}
