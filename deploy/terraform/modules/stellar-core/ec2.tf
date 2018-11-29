resource "aws_instance" "this" {
  key_name                    = "${var.instance_key_pair_name}"
  vpc_security_group_ids      = ["${aws_security_group.this.id}"]
  subnet_id                   = "${data.aws_subnet.default.id}"
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "${var.instance_type}"
  iam_instance_profile        = "${aws_iam_instance_profile.this.id}"
  associate_public_ip_address = true
  disable_api_termination     = false

  root_block_device = [
    {
      volume_type = "standard" # magnetic
      volume_size = 20
    },
  ]

  lifecycle {
    ignore_changes = ["id", "private_ip", "ami", "root_block_device", "ebs_optimized"]
  }

  tags = {
    Name            = "${var.name}"
    type            = "stellar-core"
    stellar-network = "${var.stellar_network_name}"
  }

  volume_tags = {
    Name            = "${var.name}"
    type            = "stellar-core"
    stellar-network = "${var.stellar_network_name}"
  }

  # ansible requirement
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -qq",
      "sudo apt-get update -qq",
      "sudo apt-get install -qq python",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file(var.ssh_private_key)}"
      timeout     = "90s"
    }
  }
}

resource "aws_eip" "this" {
  vpc      = true
  instance = "${aws_instance.this.id}"

  tags = {
    Name = "${var.name}"
    type = "stellar-core"
  }
}

output "ec2" {
  description = "EC2 public DNS name"
  value       = "${aws_instance.this.public_dns}"
}

resource "aws_security_group" "this" {
  name        = "${var.name}-common-new"
  description = "Stellar Core required ports: stellar-core P2P, PostgreSQL, HTTP/S"
  vpc_id      = "${data.aws_vpc.default.id}"

  tags = {
    Name = "${var.name}-common-new"
  }
}

resource "aws_security_group_rule" "ingress_ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.this.id}"
}

resource "aws_security_group_rule" "ingress_stellar_core_p2p" {
  type        = "ingress"
  from_port   = 11625
  to_port     = 11625
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Stellar Core P2P"

  security_group_id = "${aws_security_group.this.id}"
}

resource "aws_security_group_rule" "ingress_stellar_core_control" {
  type              = "ingress"
  from_port         = 11626
  to_port           = 11626
  protocol          = "tcp"
  description       = "Stellar Core control"
  security_group_id = "${aws_security_group.this.id}"

  source_security_group_id = "${var.horizon_security_group_id}"

  # optionally omit this resource if there is not attached horizon to this stellar-core node
  count = "${var.horizon_security_group_id_count}"
}

resource "aws_security_group_rule" "egress_postgresql" {
  type        = "egress"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.this.id}"
}

resource "aws_security_group_rule" "egress_http" {
  type        = "egress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.this.id}"
}

resource "aws_security_group_rule" "egress_https" {
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.this.id}"
}

resource "aws_security_group_rule" "egress_stellar_core_p2p" {
  type        = "egress"
  from_port   = 11625
  to_port     = 11625
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Stellar Core P2P"

  security_group_id = "${aws_security_group.this.id}"
}

resource "aws_security_group_rule" "egress_datadog" {
  type        = "egress"
  from_port   = 10516
  to_port     = 10516
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "DataDog logs intake"

  security_group_id = "${aws_security_group.this.id}"
}

resource "aws_security_group_rule" "egress_telegraf" {
  type        = "egress"
  from_port   = 8086
  to_port     = 8086
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Telegraf metrics"

  security_group_id = "${aws_security_group.this.id}"
}

resource "aws_security_group_rule" "egress_apt_key_server" {
  type        = "egress"
  from_port   = 11371
  to_port     = 11371
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "apt repository key server"

  security_group_id = "${aws_security_group.this.id}"
}

# data sources to get vpc, subnet, ami, route53 details

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  vpc_id            = "${data.aws_vpc.default.id}"
  availability_zone = "${var.zone}"
  default_for_az    = true
}

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # canonical/ubuntu

  filter {
    name = "name"

    # latest image
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*",
    ]
  }
}

data "aws_route53_zone" "kin" {
  name = "${format("%s.", var.tld)}"
}
