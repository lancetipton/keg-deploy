# Define the Keg Deploy VPC
resource "aws_vpc" "keg_vpc" {
  cidr_block = var.aws_vpc_cidr

  tags = {
    Name = "Keg Deploy - VPC"
  }
}

# Define the public subnet
resource "aws_subnet" "keg_public_subnet" {
  vpc_id            = aws_vpc.keg_vpc.id
  cidr_block        = var.aws_public_subnet_cidr
  availability_zone = var.aws_public_subnet_av_zone

  tags = {
    Name = "Keg Deploy - Public SBN"
  }
}

# Define the private subnet
resource "aws_subnet" "keg_private_subnet" {
  vpc_id            = aws_vpc.keg_vpc.id
  cidr_block        = var.aws_private_subnet_cidr
  availability_zone = var.aws_private_subnet_av_zone

  tags = {
    Name = "Keg Deploy - Private SBN"
  }
}

# Define the internet gateway
resource "aws_internet_gateway" "keg_gw" {
  vpc_id = aws_vpc.keg_vpc.id

  tags = {
    Name = "Keg Deploy - VPC-IGW"
  }
}

# Define the route table
resource "aws_route_table" "keg_public_rt" {
  vpc_id = aws_vpc.keg_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.keg_gw.id
  }

  tags = {
    Name = "Keg Deploy - Public RT"
  }
}

# Assign the route table to the public Subnet
resource "aws_route_table_association" "keg_public_rt" {
  subnet_id      = aws_subnet.keg_public_subnet.id
  route_table_id = aws_route_table.keg_public_rt.id
}

