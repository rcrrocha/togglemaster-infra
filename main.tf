resource "aws_vpc" "togglemaster" {

  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "togglemaster-vpc"
  }
}
resource "aws_subnet" "public_a" {
  vpc_id = aws_vpc.togglemaster.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
  Name = "public-a"
  }
}
  resource "aws_subnet" "public_b" {
  vpc_id = aws_vpc.togglemaster.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
  Name = "public-b"
  }
}
  resource "aws_subnet" "private_a" {
  vpc_id = aws_vpc.togglemaster.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "us-east-1a"
  tags = {
  Name = "private-a"
  }
}
  resource "aws_subnet" "private_b" {
  vpc_id = aws_vpc.togglemaster.id
  cidr_block = "10.0.11.0/24"
  availability_zone = "us-east-1b"
  tags = {
  Name = "private-b"
  }
}
