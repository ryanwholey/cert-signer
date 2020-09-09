resource "aws_security_group" "bastion" {
  name   = "bastion"
  vpc_id = data.terraform_remote_state.platform.outputs.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion"
  }
}

resource "aws_launch_template" "bastion" {
  name_prefix          = "bastion-"
  instance_type        = "t3.small"
  image_id             = data.aws_ami.fedora_coreos.id

  iam_instance_profile {
    name = aws_iam_instance_profile.bastion.name
  }

  vpc_security_group_ids = [aws_security_group.bastion.id]

  user_data = base64encode(jsonencode({
    ignition = {
      version = "3.0.0"
      config = {
        replace = {
          source = "s3://${aws_s3_bucket.ignition_configs.bucket}/${aws_s3_bucket_object.bastion.id}"
        }
      }
    }
  }))
}

resource "aws_autoscaling_group" "bastion" {
  name = "bastion"

  max_size         = 2
  min_size         = 2
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.bastion.id
    version = "$Latest"
  }

  vpc_zone_identifier = data.terraform_remote_state.platform.outputs.public_subnet_ids

  target_group_arns = [
    aws_lb_target_group.bastion.arn
  ]

  tags = [
    {
      key                 = "Name"
      value               = "bastion"
      propagate_at_launch = true
    }
  ]
}

data "ct_config" "bastion" {
  content = templatefile("${path.module}/templates/bastion.yaml", {
    ca_client_public_key = vault_ssh_secret_backend_ca.client_ca.public_key
    vault_addr           = data.terraform_remote_state.platform.outputs.vault_addr
    vault_role_id        = vault_approle_auth_backend_role.instance.role_id
    vault_secret_id      = vault_approle_auth_backend_role_secret_id.instance.secret_id
  })
  pretty_print = false
}

resource "aws_s3_bucket_object" "bastion" {
  bucket  = aws_s3_bucket.ignition_configs.id
  key     = "bastion-ignition.json"
  content = data.ct_config.bastion.rendered
}

resource "aws_iam_role" "bastion" {
  name = "bastion"

  assume_role_policy = data.aws_iam_policy_document.trust.json
}

resource "aws_iam_role_policy_attachment" "bastion_ignition" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.ignition.arn
}

resource "aws_iam_instance_profile" "bastion" {
  name = "bastion"
  role = aws_iam_role.bastion.name
}

resource "aws_route53_record" "bastion" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "bastion.${var.hosted_zone}"
  type    = "A"

  alias {
    name                   = aws_lb.nlb.dns_name
    zone_id                = aws_lb.nlb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_lb" "nlb" {
  name               = "bastion-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = data.terraform_remote_state.platform.outputs.public_subnet_ids

  enable_deletion_protection = false
}

resource "aws_lb_listener" "forwarder" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 22
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bastion.arn
  }
}

resource "aws_lb_target_group" "bastion" {
  name        = "bastion-group"
  port        = 22
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = data.terraform_remote_state.platform.outputs.vpc_id
}

output "bastion" {
  value = {
    dns = aws_route53_record.bastion.name
  }
}
