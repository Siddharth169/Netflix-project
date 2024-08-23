provider "aws" {
  region = "us-east-1"
}

variable "ami_id" {
  type = string
  description = "Enter the requested ami id"
}

resource "aws_vpc" "netflix-vpc" {
  cidr_block = "10.0.0.0/16"  
  tags = {
    Name = "Netflix"
  }
}

/*resource "aws_subnet" "private-subnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.netflix-vpc.id
  availability_zone = "us-east-1a"
  tags = {
    Name = "Private"
  }
}*/

resource "aws_subnet" "public-subnet" {
  cidr_block = "10.0.2.0/24"
  vpc_id = aws_vpc.netflix-vpc.id
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public"
  }
}

resource "aws_internet_gateway" "jenkins-igw" {
  vpc_id = aws_vpc.netflix-vpc.id
  tags = {
    Name = "Jenkins_igw"
  }
}

resource "aws_route_table" "jenkins-rt" {
  vpc_id = aws_vpc.netflix-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins-igw.id
  }
}

resource "aws_route_table_association" "jenkins-rts" {
  subnet_id = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.jenkins-rt.id
}

resource "aws_security_group" "jenkins-server-sg" {
  vpc_id = aws_vpc.netflix-vpc.id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
    from_port = 22
    to_port = 22
  }
  
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
    from_port = 8080
    to_port = 8080
    description = "Jenkins application"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
    from_port = 9000
    to_port = 9000
    description = "sonarqube"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol = -1
    from_port = 0
    to_port = 0
  }
  tags = {
    Name = "Jenkins-server-sg"
  }
}

resource "aws_key_pair" "Jenkins-key" {
  key_name = "Jenkins-key"
  public_key = file("~/.ssh/ec2.pub")
}

resource "aws_instance" "Jenkins" {
  ami = var.ami_id
  instance_type = "t3.medium"
  key_name = aws_key_pair.Jenkins-key.key_name
  vpc_security_group_ids = ["aws_security_group.jenkins-server-sg.id"]
  subnet_id = aws_subnet.public-subnet.id
  tags = {
    Name = "Jenkins-server"
  }
  user_data = file("./jenkins-installation.sh") #we can also use provisioner (remote-exec) to deploy the service we want to installing the resource creating
}

output "public_ip" {
  description = "Public_IP"
  value = aws_instance.Jenkins.public_ip
}