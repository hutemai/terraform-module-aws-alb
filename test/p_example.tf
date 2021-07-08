module "alb" {
  # source = "github.com/lean-delivery/tf-module-aws-alb?ref=13"
  source = "../../../../local_tf_moudles/terraform-module-aws-alb"

  project     = data.terraform_remote_state.core.outputs.project
  environment = local.environment

  enable_subdomains = "true"

  vpc_id  = data.terraform_remote_state.core.outputs.vpc_id
  subnets = data.terraform_remote_state.core.outputs.public_subnets

  default_load_balancer_is_internal = "false"

  acm_cert_domain = data.aws_partition.current.partition == "aws" ? module.acm-cert.certificate_domain : "cn-north-1.elb.amazonaws.com.cn"

  most_recent_certificate = true

  root_domain                = var.root_domain

  alb_logs_lifecycle_rule_enabled = true
  alb_logs_expiration_days        = var.alb_logs_retention

  target_groups = [{
    name                             = "${data.terraform_remote_state.core.outputs.project}-${local.environment}"
    backend_protocol                 = var.proxy_protocol
    backend_port                     = var.proxy_port
    deregistration_delay             = 5
    target_type                      = "ip"
    slow_start                       = 0
    load_balancing_algorithm_type    = "round_robin"
    health_check = {
      interval = 5
      healthy_threshold = 2
      path = "/healthcheck"
      unhealthy_threshold = 2
      port = "traffic-port"
      timeout = 4
      matcher = "200"
    }
    stickiness = {
      enabled = false
      type    = "lb_cookie"
    }
  }]

  depends_on = [
    module.acm-cert,
  ]
}