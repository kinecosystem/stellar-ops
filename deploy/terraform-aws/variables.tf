#########################
# Variables to override #
#########################

variable "NODENAME" {
  description = "The Name of the Node Partner"
  default = "node"
}

variable "SUFFIX" {
  description = "Unique suffix for Node"
  default = "suf42"
}

variable "DB_USER" { default = "stellar" }
variable "DB_PASS" { default = "defaultpassword" }
variable "DB_NAME" { default = "core" }
variable "DB_IDENTIFIER" { default = "stellar-core-db" }

#####################
# Key to launch EC2 #
#####################

variable "key_path" {
  description = "SSH Public Key path"
  #default = "/root/.ssh/id_rsa.pub"
  default = "~/terraform7/ec2key/key.pub"
}

#######################
# Region to deploy on #
#######################

variable "aws_region" {
  description = "Region for the VPC"
}

#######################
# Application Subnets # 
#######################

variable "app_vpc_cidr" {
  description = "CIDR for the VPC"
  default = "172.31.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet"
  default = "172.31.16.0/20"
}

variable "public_b_subnet_cidr" {
  description = "CIDR for the public subnet"
  default = "172.31.32.0/20"
}

variable "private_subnet_cidr" {
  description = "CIDR for the private subnet"
  default = "172.31.0.0/20"
}

variable "private_subnet_b_cidr" {
  description = "CIDR for the private subnet"
  default = "172.31.48.0/20"
}

variable "ami" {
  description = "Amazon Linux AMI"
  default = "ami-0d8f6eb4f641ef691"
}

#####################
# Managment Subnets #
#####################

variable "mng_vpc_cidr" {
  description = "CIDR for the VPC"
  default = "10.0.0.0/16"
}

variable "dmz_subnet_cidr" {
  description = "CIDR for the public subnet"
  default = "10.0.0.0/20"
}
