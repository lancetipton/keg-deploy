data "http" "ip" {
  url = "https://checkip.amazonaws.com/"
}

resource "aws_security_group" "keg_sg_public" {
  name        = "keg-deploy-public-sg"
  description = "Allow incoming HTTP connections & SSH access"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.keg_vpc.id

  tags = {
    Name = "Keg Deploy - Public SG"
  }
}

# Define the security group for private subnet
resource "aws_security_group" "keg_sg_private" {
  name        = "keg-deploy-private-sg"
  description = "Allow traffic from public subnet"

  # allow ssh for ip of machine running terraform apply
  ingress {
    description = "User IP (for terraform apply)"
    from_port = 22 
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${chomp(data.http.ip.body)}/32"] 
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.aws_public_subnet_cidr]
  }

  ingress {
    description     = "all-traffic from the public and private security groups"
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    security_groups = [aws_security_group.keg_sg_public.id]
    self            = true
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.aws_public_subnet_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.aws_public_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.keg_vpc.id

  tags = {
    Name = "Keg Deploy - Private SG"
  }
}

