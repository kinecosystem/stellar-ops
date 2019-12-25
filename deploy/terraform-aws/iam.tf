resource "aws_iam_role" "stellar_role" {
  name = "stellar_assume_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
      tag-key = "Stellar-Assume-Role"
  }
}

resource "aws_iam_instance_profile" "stellar_profile" {
  name = "stellar_profile"
  role = "${aws_iam_role.stellar_role.name}"
}

resource "aws_iam_role_policy" "stellar_policy" {
  name = "stellar_policy"
  role = "${aws_iam_role.stellar_role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::stellar-core-${var.NODENAME}-${var.SUFFIX}/*"
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:GetMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics"
            ],
            "Resource": "*"
        }
    ]
 }
EOF
}

