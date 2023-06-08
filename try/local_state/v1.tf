# Configure the AWS provider
provider "aws" {
  region = "eu-north-1"
}

# Create a VPC with a given CIDR block
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

# Create a public subnet in the VPC with a given CIDR block
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"
}

# Create a private subnet in the VPC with a given CIDR block
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"
}

# Create an Internet Gateway in the VPC and attach it to the public subnet
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
}

# Associate the public subnet with the public Route Table and create a default route to the Internet Gateway
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route" "public_internet_gateway" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id     = aws_internet_gateway.example.id
}

# Create a NAT Gateway in the private subnet and create an Elastic IP for it
resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.private.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.example.id
}

# Associate the private subnet with the private Route Table and create a default route to the NAT Gateway
resource "aws_route_table_association" "private" {
subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}