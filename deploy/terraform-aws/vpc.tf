##############################
#   Subnet Group for RDS     #
##############################

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = ["${aws_subnet.private-subnet.id}", "${aws_subnet.public-subnet.id}"]

  tags = {
    Name = "My DB subnet group"
  }
}

##############################
#   Application VPC          #
##############################

# Define our VPC
resource "aws_vpc" "Application-VPC" {
  cidr_block = "${var.app_vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    Name = "Application-VPC"
  }
}

# Define the internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.Application-VPC.id}"

  tags {
    Name = "App-VPC-IGW"
  }
}

# Define the public route table
resource "aws_route_table" "web-public-rt" {
  vpc_id = "${aws_vpc.Application-VPC.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  route {
    cidr_block = "10.0.0.0/24"
    gateway_id = "${aws_vpc_peering_connection.dmztofed.id}"
  }

  tags {
    Name = "Fed-Public-RT"
  }
}

# Assign the route table to the public Subnet
resource "aws_route_table_association" "web-public-attach" {
  subnet_id = "${aws_subnet.public-subnet.id}"
  route_table_id = "${aws_route_table.web-public-rt.id}"
}

resource "aws_route_table_association" "web-public-attach-b" {
  subnet_id = "${aws_subnet.public-subnet-b.id}"
  route_table_id = "${aws_route_table.web-public-rt.id}"
}

resource "aws_main_route_table_association" "public-main-rt" {
  vpc_id         = "${aws_vpc.Application-VPC.id}"
  route_table_id = "${aws_route_table.web-public-rt.id}"
}

# Define the private route table
resource "aws_route_table" "web-private-rt" {
  vpc_id = "${aws_vpc.Application-VPC.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.stellar_nat_gw.id}"
  }
  route {
    cidr_block = "10.0.0.0/24"
    gateway_id = "${aws_vpc_peering_connection.dmztofed.id}"
  }

  tags {
    Name = "Fed-Private-RT"
  }
}

# Assign the route table to the Private Subnet
resource "aws_route_table_association" "fed-rt-attach" {
  subnet_id = "${aws_subnet.private-subnet.id}"
  route_table_id = "${aws_route_table.web-private-rt.id}"
}

resource "aws_route_table_association" "fed-rt-attach-b" {
  subnet_id = "${aws_subnet.private-subnet-b.id}"
  route_table_id = "${aws_route_table.web-private-rt.id}"
}

#####################
# Managment - VPC   #
#####################
# Define our VPC
resource "aws_vpc" "Managment-VPC" {
  cidr_block = "${var.mng_vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    Name = "Managment-Vpc"
  }
}

# Define the internet gateway
resource "aws_internet_gateway" "gw-dmz" {
  vpc_id = "${aws_vpc.Managment-VPC.id}"

  tags {
    Name = "Mng-Vpc-IGW"
  }
}

# Define the route table
resource "aws_route_table" "dmz-rt" {
  vpc_id = "${aws_vpc.Managment-VPC.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw-dmz.id}"
  }

  route {
    cidr_block = "172.31.0.0/16"
    gateway_id = "${aws_vpc_peering_connection.dmztofed.id}"
  }

  tags {
    Name = "Managment-RT"
  }
}

# Assign the route table to the public Subnet
resource "aws_route_table_association" "dmz-rt-attach" {
  subnet_id = "${aws_subnet.dmz-subnet.id}"
  route_table_id = "${aws_route_table.dmz-rt.id}"
}

resource "aws_main_route_table_association" "dmz-main-rt" {
  vpc_id         = "${aws_vpc.Managment-VPC.id}"
  route_table_id = "${aws_route_table.dmz-rt.id}"
}



######################
# Peering connection #
######################

resource "aws_vpc_peering_connection" "dmztofed" {
  peer_vpc_id   = "${aws_vpc.Managment-VPC.id}"
  vpc_id        = "${aws_vpc.Application-VPC.id}"
  auto_accept   = true

  tags = {
    Name = "VPC Peering between DMZ and Fed"
  }
}

#############################

