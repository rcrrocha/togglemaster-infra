resource "aws_vpc" "togglemaster" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "togglemaster-vpc"
  }
}
