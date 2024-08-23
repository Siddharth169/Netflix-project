provider "aws" {
  region = "us-east-1"
}

variable "ami_id" {
  type = string
  description = "Enter the requested ami id"
}

resource "aws_key_pair" "Jenkins-key" {
  key_name = "Jenkins-key"
  public_key = file("~/.ssh/ec2.pub")
}

resource "aws_instance" "Jenkins" {
  ami = var.ami_id
  instance_type = "t3.medium"
  key_name = aws_key_pair.Jenkins-key.key_name
  tags = {
    Name = "Jenkins-server"
  }
  user_data = file("./jenkins-installation.sh")
}

output "public_ip" {
  description = "Public_IP"
  value = aws_instance.Jenkins.public_ip
}