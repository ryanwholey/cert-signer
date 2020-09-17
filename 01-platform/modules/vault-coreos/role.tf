data "aws_iam_policy_document" "trust_relationship" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "AWS"
      identifiers = var.trusted_principals
    }

    principals {
      type        = "Service"
      identifiers = var.trusted_services
    }
  }
}

resource "aws_iam_role" "vault_server" {
  name               = "vault-server"
  assume_role_policy = data.aws_iam_policy_document.trust_relationship.json
}

resource "aws_iam_role_policy_attachment" "vault_unseal" {
  role       = aws_iam_role.vault_server.name
  policy_arn = aws_iam_policy.kms.arn
}

resource "aws_iam_role_policy_attachment" "storage" {
  role       = aws_iam_role.vault_server.name
  policy_arn = aws_iam_policy.storage.arn
}
