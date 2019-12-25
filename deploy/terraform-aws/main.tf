###############################
##   AWS  Connection config ##
##############################

provider "aws" {
  region                  = "${var.aws_region}"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "default"
}



#terraform {
#  backend "s3" {
#    encrypt = true
    # cannot contain interpolations
     #bucket = "${aws_s3_bucket.tf_bucket.bucket}"
    #bucket = "my-terraform-state-s3"
     #region = "${aws_s3_bucket.tf_bucket.region}"
#    region = "us-east-2"
    # dynamodb_table = "example-iac-terraform-state-lock-dynamo"
#    key = "terraform.tfstate"
#  }
#}
