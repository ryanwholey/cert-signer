resource "aws_kms_key" "seal" {
  description = "KMS key that can seal and auto-unseal Vault (https://learn.hashicorp.com/vault/operations/ops-autounseal-aws-kms)"
}

resource "aws_kms_alias" "seal" {
  name          = "alias/vault-seal"
  target_key_id = aws_kms_key.seal.key_id
}

# https://www.vaultproject.io/docs/configuration/seal/awskms.html
data "aws_iam_policy_document" "kms_unseal" {
  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = [
      aws_kms_key.seal.arn
    ]
  }
}

resource "aws_iam_policy" "kms" {
  name        = "vault-seal"
  description = "Allows Vault to seal and unseal using KMS"
  policy      = data.aws_iam_policy_document.kms_unseal.json
}

