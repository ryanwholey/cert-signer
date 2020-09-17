
data "aws_route53_zone" "current" {
  name = var.hosted_zone
}

data "aws_elb_hosted_zone_id" "current" {}

resource "aws_security_group" "vault_lb" {
  name        = "vault-${var.name}-lb"
  description = "Allow Vault ingress and egress"
  vpc_id      = var.vpc_id

  # Vault client
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.client_ingress_cidrs
  }

  # Allow all egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vault-${var.name}-lb"
  }
}

resource "aws_lb" "alb" {
  name               = "vault-${var.name}"
  load_balancer_type = "application"
  internal           = var.is_public == true ? false : true
  security_groups    = [aws_security_group.vault_lb.id]
  subnets            = var.subnet_ids

  tags = {
    Name = "vault-${var.name}"
  }
}

resource "aws_lb_listener" "forwarder" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.vault.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault.arn
  }
}

resource "aws_lb_target_group" "vault" {
  name        = "vault-${var.name}"
  vpc_id      = var.vpc_id
  target_type = "instance"

  protocol = "HTTPS"
  port     = var.server_port

  health_check {
    protocol = "HTTPS"
    port     = var.server_port
    path     = "/v1/sys/health?standbyok=true"

    healthy_threshold   = 3
    unhealthy_threshold = 3

    interval = 10
  }
}

resource "aws_lb_target_group_attachment" "vault" {
  for_each = aws_instance.vault

  target_group_arn = aws_lb_target_group.vault.arn
  target_id        = each.value.id
}

resource "aws_route53_record" "vault" {
  name    = "vault.${var.name}.${var.hosted_zone}"
  type    = "A"
  zone_id = data.aws_route53_zone.current.id

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = data.aws_elb_hosted_zone_id.current.id
    evaluate_target_health = false
  }
}


resource "aws_acm_certificate" "vault" {
  domain_name       = "*.${var.name}.${var.hosted_zone}"
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "vault" {
  certificate_arn = aws_acm_certificate.vault.arn
}

resource "aws_route53_record" "validation" {
  zone_id = data.aws_route53_zone.current.id

  name    = aws_acm_certificate.vault.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.vault.domain_validation_options[0].resource_record_type
  records = [aws_acm_certificate.vault.domain_validation_options[0].resource_record_value]

  ttl = 60
}
