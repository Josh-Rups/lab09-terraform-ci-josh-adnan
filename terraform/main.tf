terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = var.cidr_vpc
  tags       = { Name = "${var.name_prefix}-vpc" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.name_prefix}-igw" }
}

# Public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.cidr_public_subnet
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name_prefix}-public" }
}

# Route table + route to IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.name_prefix}-public-rt" }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate route table to subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security group allowing HTTP (80) only
resource "aws_security_group" "web" {
  name        = "${var.name_prefix}-web-sg"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from MyIP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["24.151.26.97/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-web-sg" }
}

# AMI data
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  user_data              = file("${path.module}/user_data.sh")
  tags = {
    Name = "${var.name_prefix}-web"
  }
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}
