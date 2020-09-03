resource "aws_s3_bucket" "ignition_configs" {
  bucket = "${var.bucket_prefix}-ignition-configs"
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ignition" {
  statement {
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.ignition_configs.arn,
      "${aws_s3_bucket.ignition_configs.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "ignition" {
  name   = "ignition"
  policy = data.aws_iam_policy_document.ignition.json
}
