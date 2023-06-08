# 1. Configure the AWS provider
provider "aws" {
  region = "eu-north-1"
}

# 2. Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}

# 3. Create a public subnet
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "my-public-subnet"
  }
}

# 4. Create a private subnet
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "my-private-subnet"
  }
}

# 5. Create a route table for the public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "my-public-route-table"
  }
}

# 6. Associate the route table with the public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 7. Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-internet-gateway"
  }
}

# 8. Create a NAT Gateway in the private subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "my-nat-gateway"
  }
}

# 9. Create an Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {
  vpc = true
}

# 10. Create a route table for the private subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "my-private-route-table"
  }
}

# 11. Associate the route table with the private subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# 12. Create an EC2 instance in the public subnet
resource "aws_instance" "public" {
  ami           = "ami-017ff17a3b372f3d8" # AMI ID for Ubuntu Server 22.04 LTS in eu-north-1
  instance_type = "t2.micro"
  key_name      = "bb-key"

  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sg.id]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8 # Size in GB of the root volume (SSD)
    delete_on_termination = true
  }

  tags = {
    Name = "my-public-instance"
  }
}

# 13. Create an EC2 instance in the private subnet
resource "aws_instance" "private" {
  ami           = "ami-017ff17a3b372f3d8" # AMI ID for Ubuntu Server 22.04 LTS in eu-north-1
  instance_type = "t2.micro"
  key_name      = "bb-key"

  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.sg.id]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8 # Size in GB of the root volume (SSD)
    delete_on_termination = true
  }

  tags = {
    Name = "my-private-instance"
  }
}

# 14. Create a security group to allow incoming traffic to the EC2 instances
resource "aws_security_group" "sg" {
  name        = "my-security-group"
  description = "Allow incoming traffic to the EC2 instances"
  vpc_id      = aws_vpc.main.id

  # 15. Allow incoming traffic on port 22 (SSH) from any IP address
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 16. Allow all outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 17. Generate an Ansible inventory file dynamically
resource "local_file" "inventory" {
 content = templatefile("${path.module}/inventory.tpl", {
    public_ip  = aws_instance.public.public_ip
    private_ip = aws_instance.private.private_ip
  })
  filename = "${path.module}/inventory.ini"
}
