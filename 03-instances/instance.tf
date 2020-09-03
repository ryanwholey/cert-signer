resource "aws_security_group" "instance" {
  name   = "instance"
  vpc_id = data.terraform_remote_state.platform.outputs.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.platform.outputs.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance"
  }
}

resource "aws_instance" "instance" {
  ami           = data.aws_ami.fedora_coreos.id
  instance_type = "t3.small"

  vpc_security_group_ids = [aws_security_group.instance.id]

  iam_instance_profile = aws_iam_instance_profile.instance.name

  user_data = base64encode(jsonencode({
    ignition = {
      version = "3.0.0"
      config = {
        replace = {
          source = "s3://${aws_s3_bucket.ignition_configs.bucket}/${aws_s3_bucket_object.instance.id}"
        }
      }
    }
  }))

  subnet_id = [for id in data.terraform_remote_state.platform.outputs.public_subnet_ids : id][0]

  tags = {
    Name = "instance"
  }
}

data "ct_config" "instance" {
  content = templatefile("${path.module}/templates/instance.yaml", {
    ca_client_public_key = vault_ssh_secret_backend_ca.client_ca.public_key
  })
  pretty_print = false
}

resource "aws_s3_bucket_object" "instance" {
  bucket  = aws_s3_bucket.ignition_configs.id
  key     = "instance-ignition.json"
  content = data.ct_config.instance.rendered
}

resource "aws_iam_role" "instance" {
  name = "instance"

  assume_role_policy = data.aws_iam_policy_document.trust.json
}

resource "aws_iam_role_policy_attachment" "instance_ignition" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.ignition.arn
}

resource "aws_iam_instance_profile" "instance" {
  name = "instance"
  role = aws_iam_role.instance.name
}

output "instance" {
  value = aws_instance.instance.private_ip
}

