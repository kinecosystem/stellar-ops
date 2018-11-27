resource "aws_instance" "this" {
  key_name                = "${var.instance_key_pair_name}"
  vpc_security_group_ids  = ["${module.ec2_security_group.this_security_group_id}"]
  subnet_id               = "${data.aws_subnet.default.id}"
  ami                     = "${data.aws_ami.ubuntu.id}"
  instance_type           = "${var.instance_type}"
  disable_api_termination = false

  associate_public_ip_address = true # TODO unncessary, behind ALB

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
    type            = "horizon"
    stellar-network = "${var.stellar_network_name}"
  }

  volume_tags = {
    Name            = "${var.name}"
    type            = "horizon"
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

module "ec2_security_group" {
  source              = "terraform-aws-modules/security-group/aws"
  name                = "${var.name}"
  description         = "Horizon required ports: PostgreSQL, HTTP/S"
  vpc_id              = "${data.aws_vpc.default.id}"
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp", "http-80-tcp"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
  egress_rules        = ["postgresql-tcp", "http-80-tcp", "https-443-tcp"]

  ingress_with_cidr_blocks = [
    {
      from_port   = 8001
      to_port     = 8001
      protocol    = "tcp"
      description = "ALB Horizon health check"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 11626
      to_port     = 11626
      protocol    = "tcp"
      description = "Stellar Core control"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 10516
      to_port     = 10516
      protocol    = "tcp"
      description = "DataDog logs intake"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 8086
      to_port     = 8086
      protocol    = "tcp"
      description = "telegraf"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 11371
      to_port     = 11371
      protocol    = "tcp"
      description = "apt repository key server"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

output "ec2" {
  description = "EC2 public DNS name"
  value       = "${aws_instance.this.public_dns}"
}

output "ec2_security_group_id" {
  description = "EC2 security group id"
  value       = ["${module.ec2_security_group.this_security_group_id}"]
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
