terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

data "aws_caller_identity" "current" {}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

# Get the latest Amazon Linux 2023 AMI
data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Get the current AWS account ID
data "aws_caller_identity" "current" {}

# 1. Create VPC
resource "aws_vpc" "pankajvpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "pankajvpc"
  }
}

# 2. Create public subnet
resource "aws_subnet" "pankaj_public_subnet" {
  vpc_id                  = aws_vpc.pankajvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "pankaj-public-subnet"
  }
}

# 3. Create Internet Gateway
resource "aws_internet_gateway" "pankaj_igw" {
  vpc_id = aws_vpc.pankajvpc.id

  tags = {
    Name = "pankaj-igw"
  }
}

# 4. Create public route table
resource "aws_route_table" "pankaj_public_rt" {
  vpc_id = aws_vpc.pankajvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pankaj_igw.id
  }

  tags = {
    Name = "pankaj-public-rt"
  }
}

# 5. Associate route table with subnet
resource "aws_route_table_association" "pankaj_public_rta" {
  subnet_id      = aws_subnet.pankaj_public_subnet.id
  route_table_id = aws_route_table.pankaj_public_rt.id
}

# 6. Security group - SSH from your IP only
resource "aws_security_group" "pankaj_ec2_sg" {
  name        = "pankaj-ec2-sg"
  description = "Allow SSH from my public IP"
  vpc_id      = aws_vpc.pankajvpc.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_PUBLIC_IP/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pankaj-ec2-sg"
  }
}

# 7. Create EC2 instance
resource "aws_instance" "pankaj_ec2" {
  ami                         = data.aws_ssm_parameter.amazon_linux.value
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.pankaj_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.pankaj_ec2_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "pankaj-ec2"
  }
}

# 8. Outputs
output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "vpc_id" {
  value = aws_vpc.pankajvpc.id
}

output "subnet_id" {
  value = aws_subnet.pankaj_public_subnet.id
}

output "ec2_instance_id" {
  value = aws_instance.pankaj_ec2.id
}

output "ec2_public_ip" {
  value = aws_instance.pankaj_ec2.public_ip
}
