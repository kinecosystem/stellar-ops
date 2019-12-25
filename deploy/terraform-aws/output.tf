output "aws_eip_natip" {
  value = "${aws_eip.nat.public_ip}"
  description = "The NAT IP address of the Stellar Subnet for Whitelisting"
}





