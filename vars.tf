variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "aws_region" {
  default = "eu-west-1"
}

variable "ec2_ami_eu_central_1" {
  description = "Image for all instance"
  default     = "ami-09def150731bdbcc2"
}

variable "ec2_ami_eu_west_1" {
  description = "Image for all instance"
  default     = "ami-0bbc25e23a7640b9b"
}

variable "myprivate_key" {
  default = "../.ssh/id_rsa"
}

variable "mypublic_key" {
  default = "../.ssh/id_rsa.pub"
}
