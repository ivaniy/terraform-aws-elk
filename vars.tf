variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "ec2_ami" {
  description = "Image for all instance"
  default     = "ami-09def150731bdbcc2"
}

variable "myprivate_key" {
  default = "../.ssh/id_rsa"
}

variable "mypublic_key" {
  default = "../.ssh/id_rsa.pub"
}
