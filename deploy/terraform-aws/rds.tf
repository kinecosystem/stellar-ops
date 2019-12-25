
resource "aws_db_subnet_group" "postgres-subnet" {
  name = "postgres-subnet"
  description = "RDS subnet group"
  subnet_ids = ["${aws_subnet.private-subnet.id}","${aws_subnet.private-subnet-b.id}"]
}

resource "aws_db_parameter_group" "postgres-parameters" {
name = "postgres-parameters"
family = "postgres9.6"
description = "postgres parameter group"

#parameter {
  #name = "max_allowed_packet"
  #value = "16777216"
  #}
}

resource "aws_db_instance" "postgres" {
  allocated_storage = 100 # 100 GB of storage, gives us more IOPS than a lower number
  engine = "postgres"
  engine_version = "9.6.11"
  instance_class = "db.m4.xlarge"
  identifier = "${var.DB_IDENTIFIER}"
  name = "${var.DB_NAME}"
  username = "${var.DB_USER}" 
  password = "${var.DB_PASS}"
  db_subnet_group_name = "${aws_db_subnet_group.postgres-subnet.name}"
  parameter_group_name = "${aws_db_parameter_group.postgres-parameters.name}"
  multi_az = "false" # set to true to have high availability: 2 instances synchronized with each other
  vpc_security_group_ids = ["${aws_security_group.allow-postgres.id}"]
  storage_type = "gp2"
  #backup_retention_period = 30 
  availability_zone = "${aws_subnet.private-subnet.availability_zone}" # prefered AZ

tags {
  Name = "postgres-instance"
  }
}
