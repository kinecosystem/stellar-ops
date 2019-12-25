######################
# Application - VPC  #
######################

# Define main public subnet
resource "aws_subnet" "public-subnet" {
  vpc_id = "${aws_vpc.Application-VPC.id}"
  cidr_block = "${var.public_subnet_cidr}"
  availability_zone = "${var.aws_region}a"

  tags {
    Name = "App Public Subnet-1"
  }
}


# Define second public subnet
resource "aws_subnet" "public-subnet-b" {
  vpc_id = "${aws_vpc.Application-VPC.id}"
  cidr_block = "${var.public_b_subnet_cidr}"
  availability_zone = "${var.aws_region}b"

  tags {
    Name = "App Public Subnet-2"
  }
}

# Define main private subnet
resource "aws_subnet" "private-subnet" {
  vpc_id = "${aws_vpc.Application-VPC.id}"
  cidr_block = "${var.private_subnet_cidr}"
  availability_zone = "${var.aws_region}b"

  tags {
    Name = "App Private Subnet-1"
  }
}

# Define second private subnet
resource "aws_subnet" "private-subnet-b" {
  vpc_id = "${aws_vpc.Application-VPC.id}"
  cidr_block = "${var.private_subnet_b_cidr}"
  availability_zone = "${var.aws_region}a"

  tags {
    Name = "App Private Subnet-2"
  }
}

###################
# Managment - VPC #
###################

# Define the public subnet
resource "aws_subnet" "dmz-subnet" {
  vpc_id = "${aws_vpc.Managment-VPC.id}"
  cidr_block = "${var.dmz_subnet_cidr}"
  availability_zone = "${var.aws_region}a"

  tags {
    Name = "DMZ-Subnet"
  }
}
