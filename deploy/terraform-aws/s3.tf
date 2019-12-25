resource "aws_s3_bucket" "tf_bucket" {
  bucket = "${var.NODENAME}-${var.SUFFIX}-tf-state"
  acl    = "private"
  tags = {
    Name        = "TF-bucket"
  }
}

resource "aws_s3_bucket" "stellar_bucket" {
  bucket = "stellar-core-${var.NODENAME}-${var.SUFFIX}"
  acl    = "public-read"
  policy = <<EOF
{
  "Id": "bucket_policy_site",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "bucket_policy_site_main",
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::stellar-core-${var.NODENAME}-${var.SUFFIX}/*",
      "Principal": "*"
    }
  ]
}
EOF
  tags = {
    Name        = "My-TF-bucket"
  }
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${var.NODENAME}-${var.SUFFIX}-cloudtrail-logs"
  acl    = "private"
  tags = {
    Name        = "Cloudtrail-bucket"
  }
}

resource "aws_s3_bucket" "conf_bucket" {
  bucket = "${var.NODENAME}-${var.SUFFIX}-config-bucket"
  acl    = "private"

  tags = {
    Name        = "Config-bucket"
  }
}
