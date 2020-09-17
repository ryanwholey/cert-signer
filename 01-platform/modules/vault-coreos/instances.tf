data "aws_region" "current" {}

resource "aws_security_group" "vault_instance" {
  name   = "vault-${var.name}-instances"
  vpc_id = var.vpc_id

  # ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_ingress_cidrs
  }

  # client ingress
  ingress {
    from_port       = var.server_port
    to_port         = var.server_port
    protocol        = "tcp"
    security_groups = [aws_security_group.vault_lb.id]
    cidr_blocks     = var.peer_ingress_cidrs
  }

  # peer negotiation ingress
  ingress {
    from_port       = var.cluster_port
    to_port         = var.cluster_port
    protocol        = "tcp"
    cidr_blocks     = var.peer_ingress_cidrs
  }

  # Allow all egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vault-${var.name}-instances"
  }
}

data "aws_ami" "coreos" {
  most_recent = true
  owners      = ["595879546273"] # Canonical

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["CoreOS-stable-*"]
  }
}

resource "aws_instance" "vault" {
  for_each = local.instance_meta

  ami           = data.aws_ami.coreos.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.vault_instance.id]

  iam_instance_profile = aws_iam_instance_profile.vault_instance.name

  user_data = base64encode(jsonencode({
    ignition = {
      version = "2.3.0"
      config = {
        replace = {
          source = "s3://${aws_s3_bucket.ignition_configs.id}/${aws_s3_bucket_object.user_data[each.key].id}"
        }
      }
    }
  }))

  subnet_id = each.value.subnet_id

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      ami,
      user_data,
    ]
  }

  tags = {
    Name = "${var.name}-${each.key}"
  }
}

resource "aws_route53_record" "vault_instances" {
  for_each = aws_instance.vault

  name    = "${each.key}.${var.name}.${var.hosted_zone}"
  type    = "A"
  zone_id = data.aws_route53_zone.current.zone_id
  ttl     = "300"
  records = [each.value.private_ip]
}

resource "aws_s3_bucket" "ignition_configs" {
  bucket = "${var.cert_organization}-vault-${var.name}-ignition-configs"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }
}

data "ct_config" "ignition" {
  for_each = local.instance_meta

  content = templatefile("${path.module}/templates/vault-ignition.yaml", {
    dynamo_table         = aws_dynamodb_table.storage.name
    kms_key              = aws_kms_alias.seal.name
    server_cert          = indent(10, tls_locally_signed_cert.server.cert_pem)
    server_key           = indent(10, tls_private_key.server.private_key_pem)
    ca_cert              = indent(10, tls_self_signed_cert.ca.cert_pem)
    vault_advertise_addr = "https://${each.key}.${var.name}.${var.hosted_zone}:${var.server_port}"
    vault_version        = var.vault_version
    vault_server_port    = var.server_port
    region               = data.aws_region.current.name

    authorized_keys_uri = "s3://${var.s3_authorized_keys_bucket_path}"
    ssh_user                = var.ssh_user
  })
  pretty_print = false
}

resource "aws_s3_bucket_object" "user_data" {
  for_each = data.ct_config.ignition

  bucket  = aws_s3_bucket.ignition_configs.id
  key     = "user-data-${each.key}.json"
  content = each.value.rendered
}

data "aws_iam_policy_document" "read_platform_public_keys" {
  statement {
    effect    = "Allow"
    actions   = ["s3:Get*"]
    resources = ["arn:aws:s3:::${var.s3_authorized_keys_bucket_path}"]
  }
}

resource "aws_iam_policy" "read_platform_public_keys" {
  name   = "vault-${var.name}-read-platform-public-keys"
  policy = data.aws_iam_policy_document.read_platform_public_keys.json
}

resource "aws_iam_role_policy_attachment" "read_platform_public_keys" {
  role       = aws_iam_role.vault_server.name
  policy_arn = aws_iam_policy.read_platform_public_keys.arn
}

data "aws_iam_policy_document" "read_ec2" {
  statement {
    actions   = ["ec2:Describe*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "read_ec2" {
  name   = "vault-${var.name}-read-ec2"
  policy = data.aws_iam_policy_document.read_ec2.json
}

resource "aws_iam_role_policy_attachment" "read_ec2" {
  role       = aws_iam_role.vault_server.name
  policy_arn = aws_iam_policy.read_ec2.arn
}

data "aws_iam_policy_document" "read_ignition_config" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.ignition_configs.arn}/*"]
  }
}

resource "aws_iam_policy" "read_ignition_config" {
  name   = "vault-${var.name}-read-ignition-configs-"
  policy = data.aws_iam_policy_document.read_ignition_config.json
}

resource "aws_iam_role_policy_attachment" "read_ignition_config" {
  role       = aws_iam_role.vault_server.name
  policy_arn = aws_iam_policy.read_ignition_config.arn
}

resource "aws_iam_instance_profile" "vault_instance" {
  name = "vault-${var.name}"
  role = aws_iam_role.vault_server.name
}
