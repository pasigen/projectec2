terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
}
resource "aws_vpc" "mainvp" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "demovpc"
  }
}
resource "aws_internet_gateway" "maingw" {
  vpc_id = aws_vpc.mainvp.id

  tags = {
    Name = "demogw"
  }
}
resource "aws_subnet" "mainpubsub" {
  vpc_id     = aws_vpc.mainvp.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "demopubsub"
  }
}
resource "aws_route_table" "mainpubrt" {
  vpc_id = aws_vpc.mainvp.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.maingw.id
  }

  tags = {
    Name = "demopubrt"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.mainpubsub.id
  route_table_id = aws_route_table.mainpubrt.id
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.mainvp.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
   cidr_blocks      = ["0.0.0.0/0"]
  # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  #  ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "demosg"
  }
}  

resource "aws_instance" "web" {
  ami             = "ami-0103f211a154d64a6"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.mainpubsub.id
  security_groups = ["sg-094a8c714302e2bd3"]
  

tags = {
    Name = "demoec2"
  }
}

resource "aws_ebs_volume" "example" {
  availability_zone = "us-east-2b"
  size              = 8

  tags = {
    Name = "demoebs"
  }
}
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.example.id
  instance_id = aws_instance.web.id
}