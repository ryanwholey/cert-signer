resource "aws_dynamodb_table" "storage" {
  name           = var.table_name
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity
  hash_key       = "Path"
  range_key      = "Key"

  attribute {
    name = "Path"
    type = "S"
  }

  attribute {
    name = "Key"
    type = "S"
  }
}

# https://www.vaultproject.io/docs/configuration/storage/dynamodb.html
data "aws_iam_policy_document" "storage" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:DescribeLimits",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:ListTagsOfResource",
      "dynamodb:DescribeReservedCapacityOfferings",
      "dynamodb:DescribeReservedCapacity",
      "dynamodb:ListTables",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:CreateTable",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:GetRecords",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:UpdateItem",
      "dynamodb:Scan",
      "dynamodb:DescribeTable"
    ]

    resources = [
      aws_dynamodb_table.storage.arn
    ]
  }
}

resource "aws_iam_policy" "storage" {
  name        = "vault-dynamodb-storage"
  description = "Allows Vault to use the ${aws_dynamodb_table.storage.id} DynamoDB table as a storage backend"
  policy      = data.aws_iam_policy_document.storage.json
}
