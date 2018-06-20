resource "aws_route53_record" "this" {
  zone_id = "${data.aws_route53_zone.kin.zone_id}"
  name    = "${var.name}.${var.tld}"
  records = ["${aws_elb.this.dns_name}"]
  type    = "CNAME"
  ttl     = "300"
}

output "route53" {
  description = "Route53 FQDN name assigned to the EC2 instance"
  value       = "${aws_route53_record.this.fqdn}"
}