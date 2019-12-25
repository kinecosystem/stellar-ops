
# Define SSH key pair for our instances
resource "aws_key_pair" "default" {
  key_name = "default-key"
  public_key = "${file("${var.key_path}")}"
}

##################
# EC2 Instances ##
##################
# Define stellar inside the private subnet

resource "aws_instance" "stellar" {
   ami = "${data.aws_ami.latest-ubuntu.id}"
   instance_type = "t3.medium"
   key_name = "${aws_key_pair.default.id}"
   subnet_id = "${aws_subnet.private-subnet.id}"
   vpc_security_group_ids = ["${aws_security_group.stellar-sg.id}"]
   associate_public_ip_address = false
   source_dest_check = false
   iam_instance_profile = "${aws_iam_instance_profile.stellar_profile.name}"
root_block_device {
    volume_size = "100"
    volume_type = "standard"
  }   

  tags {
    Name = "Stellar-core"
  }
}

# Define database inside the private subnet
resource "aws_instance" "bastion" {
   ami = "${data.aws_ami.latest-ubuntu.id}"
   instance_type = "t2.micro"
   key_name = "${aws_key_pair.default.id}"
   subnet_id = "${aws_subnet.dmz-subnet.id}"
   vpc_security_group_ids = ["${aws_security_group.bastion-sg.id}"]
   source_dest_check = false
root_block_device {
    volume_size = "8"
    volume_type = "standard"
  }

  tags {
    Name = "Bastion-Host"
  }
}
###################################

######################
# Define Stellar NLB #
######################
resource "aws_lb" "stellar-nlb" {
  name               = "stellar-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = ["${aws_subnet.public-subnet.id}"]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "stellar_front_end" {
  load_balancer_arn = "${aws_lb.stellar-nlb.arn}"
  port              = "11625"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.stellar-nlb-tg.arn}"
  }
}


resource "aws_lb_target_group" "stellar-nlb-tg" {
  name     = "stellar-nlb-tg"
  port     = 11625
  protocol = "TCP"
  target_type = "instance"
  vpc_id   = "${aws_vpc.Application-VPC.id}"
}

resource "aws_lb_target_group_attachment" "attach" {
  target_group_arn = "${aws_lb_target_group.stellar-nlb-tg.arn}"
  target_id        = "${aws_instance.stellar.id}"
  port             = 11625
}

###################################
# Define NAT gateway to Private Subnet
###################################

resource "aws_eip" "nat" {
  #instance = "${aws_instance.web.id}"
  vpc      = true
}


resource "aws_nat_gateway" "stellar_nat_gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public-subnet.id}"

  tags = {
    Name = "gw NAT"
  }
}

