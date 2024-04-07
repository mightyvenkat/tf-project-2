terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

// Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
}

// Resources

// main vpc 
resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16" #65536
  instance_tenancy = "default"

  tags = {
    Name = "myvpc"
  }
}

//subnet

// public subnet
resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24" #256
  availability_zone = "us-east-2a"

  tags = {
    Name = "pub-sub"
  }
}

// private subnet 
resource "aws_subnet" "pvtsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24" 
  availability_zone = "us-east-2b"

  tags = {
    Name = "pvt-sub"
  }
}

//internet gateway
resource "aws_internet_gateway" "t-igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "t-igw"
  }
}

// Route table 

// public route table
resource "aws_route_table" "pub-rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.t-igw.id
  }

  tags = {
    Name = "pub-rt"
  }
}

// private route table 
resource "aws_route_table" "pvt-rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgate.id
  }

  tags = {
    Name = "pvt-rt"
  }
}
// route table association

// public route table association
resource "aws_route_table_association" "pub-rt-asc" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.pub-rt.id
}

// private route table association
resource "aws_route_table_association" "pvt-rt-asc" {
  subnet_id      = aws_subnet.pvtsub.id
  route_table_id = aws_route_table.pvt-rt.id
}
// elastic ip 
resource "aws_eip" "eip1" {
   vpc = true
}

// Nat gate way
resource "aws_nat_gateway" "natgate" {
  allocation_id = aws_eip.eip1.id
  subnet_id     = aws_subnet.pubsub.id

  tags = {
    Name = "natgate"
  }

  
}

// security group 

// pub-seg
resource "aws_security_group" "pub-seg" {
  name        = "pub-seg"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "https"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "pub-seg"
  }
}

// pvt-seg 
resource "aws_security_group" "pvt-seg" {
  name        = "pvt-seg"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "https"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups = [aws_security_group.pub-seg.id]
    
    
  }
  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups = [aws_security_group.pub-seg.id]
    
    
  }
  ingress {
    description      = "mysql"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups = [aws_security_group.pub-seg.id]
    
    
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "pvt-seg"
  }
}
