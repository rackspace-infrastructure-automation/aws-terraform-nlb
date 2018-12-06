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

  tg_keys = "${keys(var.tg_map)}"
  lm_keys = "${keys(var.listener_map)}"
  hc_keys = "${keys(var.hc_map)}"

  tags = "${merge(var.tags, map("Environment", "${var.environment}", "ServiceProvider", "Rackspace"))}"
}
