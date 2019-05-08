provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "eu-central-1"
}

resource "aws_vpc" "terraform_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "terraform_main"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.terraform_vpc.id}"
}

resource "aws_subnet" "terraform_subnet" {
  vpc_id                  = "${aws_vpc.terraform_vpc.id}"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  depends_on              = ["aws_internet_gateway.gw"]

  tags = {
    Name = "terraform_subnet"
  }
}

resource "aws_security_group" "terraform_sg" {
  name = "terraform_sg"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kibana access from anywhere
  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.terraform_vpc.id}"
}

resource "aws_key_pair" "terraform_key" {
  key_name   = "terraform_key"
  public_key = "${file(var.mypublic_key)}"
}

resource "aws_instance" "ansible" {
  ami                    = "${var.ec2_ami}"
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.terraform_subnet.id}"
  key_name               = "terraform_key"
  vpc_security_group_ids = ["${aws_security_group.terraform_sg.id}"]

  tags = {
    Name = "ansible"
  }

  connection {
    user        = "ec2-user"
    private_key = "${file(var.myprivate_key)}"
  }

  provisioner "remote-exec" {
    inline = ["sudo yum update -y && sudo amazon-linux-extras install epel -y && sudo yum install git ansible -y ",
      "git clone https://github.com/ivaniy/ansible-elk.git",
    ]
  }

  provisioner "file" {
    content     = "${file(var.myprivate_key)}"
    destination = "/home/ec2-user/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = ["sudo chmod 400 /home/ec2-user/.ssh/id_rsa"]
  }
}

resource "aws_instance" "elk" {
  ami                    = "${var.ec2_ami}"
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.terraform_subnet.id}"
  key_name               = "terraform_key"
  vpc_security_group_ids = ["${aws_security_group.terraform_sg.id}"]

  tags = {
    Name = "elk"
  }

  connection {
    user        = "ec2-user"
    private_key = "${file(var.myprivate_key)}"
  }

  provisioner "remote-exec" {
    inline = ["sudo yum update -y "]

    #&& sudo amazon-linux-extras install epel -y && sudo yum install git ansible -y ",
    #  "git clone https://github.com/ivaniy/ansible-elk.git",
  }

  #  provisioner "file" {
  #    content     = "${file(../.ssh/id_rsa)}"
  #    destination = "/home/ec2-user/.ssh/id_rsa"
  #  }
}

resource "aws_eip" "elk_public_ip" {
  vpc                       = true
  instance                  = "${aws_instance.elk.id}"
  associate_with_private_ip = "${aws_instance.elk.private_ip}"
  depends_on                = ["aws_internet_gateway.gw"]
}

resource "aws_route" "terra_rt" {
  route_table_id         = "${aws_vpc.terraform_vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

output "aws_instance_elk_public_ip" {
  value = "${aws_eip.elk_public_ip.public_ip}"
}

output "aws_instance_ansible_public_ip" {
  value = "${aws_instance.ansible.public_ip}"
}

resource "null_resource" "cluster" {
  # Changes to any instance of the cluster requires re-provisioning

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host        = "${aws_instance.ansible.public_ip}"
    user        = "ec2-user"
    private_key = "${file(var.myprivate_key)}"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the clutser
    inline = ["cd ansible-elk",
      "sed -i 's/host_ip/${aws_eip.elk_public_ip.public_ip}/g' hosts",
      "ansible-playbook elk.yml",
    ]
  }
}
