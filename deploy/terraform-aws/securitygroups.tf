#################################################################
# Defines the security group for RDS Database - Application-VPC #
#################################################################

resource "aws_security_group" "allow-postgres" {
  vpc_id = "${aws_vpc.Application-VPC.id}"
  name = "allow-postgres"
  description = "allow-postgres"
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = ["${aws_security_group.stellar-sg.id}"] # allowing access from stellar
  }

  vpc_id="${aws_vpc.Application-VPC.id}"

  tags {
    Name = "Postgres-rds-SG"
  }
}

###########################################################
# Define the security group for Stellar - Application-VPC #
###########################################################

resource "aws_security_group" "stellar-sg" {
  name = "stellar-sg"
  description = "Allow incoming HTTP connections & SSH access"

  ingress {
    from_port = 11625
    to_port = 11625
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    #cidr_blocks =  ["0.0.0.0/0"]
    security_groups = ["${aws_security_group.bastion-sg.id}"]
  }

  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Web Access"
  }

  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Web Access"
  }

  egress {
    from_port = 11371
    to_port = 11371
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "apt repository key server"
  }

  egress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Postgres Out"
  }

  egress {
    from_port = 8086
    to_port = 8086
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Telegraf Metrics"
  }

  egress {
    from_port = 11625
    to_port = 11625
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Stelar Core P2P"
  }

  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    #cidr_blocks = ["0.0.0.0/0"]
    security_groups = ["${aws_security_group.bastion-sg.id}"]
    description = "ssh connection Bastion"
  }


  vpc_id="${aws_vpc.Application-VPC.id}"

  tags {
    Name = "Stellar-SG"
  }
}


###########################################################
# Define the security group for Bastion   - Managment-VPC #
###########################################################

resource "aws_security_group" "bastion-sg" {
  name = "bastion-sg"
  description = "Allow traffic from public subnet"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.Managment-VPC.id}"

  tags {
    Name = "Bastion-SG"
  }
}
