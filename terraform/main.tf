data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "bontech" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "BonTech-Terraform-VPC"
    Environment = "Security-Lab"
    ManagedBy   = "Terraform"
  }
}

resource "aws_internet_gateway" "bontech" {
  vpc_id = aws_vpc.bontech.id

  tags = {
    Name      = "BonTech-Terraform-IGW"
    ManagedBy = "Terraform"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.bontech.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name      = "BonTech-Terraform-Public-Subnet"
    ManagedBy = "Terraform"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.bontech.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name      = "BonTech-Terraform-Private-Subnet"
    ManagedBy = "Terraform"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name      = "BonTech-Terraform-NAT-EIP"
    ManagedBy = "Terraform"
  }
}

resource "aws_nat_gateway" "bontech" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  depends_on = [aws_internet_gateway.bontech]

  tags = {
    Name      = "BonTech-Terraform-NAT-Gateway"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.bontech.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.bontech.id
  }

  tags = {
    Name      = "BonTech-Terraform-Public-RT"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.bontech.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.bontech.id
  }

  tags = {
    Name      = "BonTech-Terraform-Private-RT"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "public" {
  name        = "bontech-public-sg"
  description = "Public web and restricted administrative access"
  vpc_id      = aws_vpc.bontech.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from trusted source only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.trusted_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "BonTech-Terraform-Public-SG"
    ManagedBy = "Terraform"
  }
}

resource "aws_security_group" "private" {
  name        = "bontech-private-sg"
  description = "Private workload access only from the bastion security group"
  vpc_id      = aws_vpc.bontech.id

  ingress {
    description     = "SSH from public bastion security group"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "BonTech-Terraform-Private-SG"
    ManagedBy = "Terraform"
  }
}

resource "aws_instance" "public" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.public.id]
  associate_public_ip_address = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8
  }

  user_data = <<-EOF_USER_DATA
    #!/bin/bash
    dnf install -y httpd
    systemctl enable httpd
    systemctl start httpd
    cat > /var/www/html/index.html <<'HTML'
    <h1>BonTech Terraform AWS Security Lab</h1>
    <p>Public web server successfully deployed using Terraform.</p>
    HTML
  EOF_USER_DATA

  tags = {
    Name        = "BonTech-Terraform-Public-Server"
    Environment = "Security-Lab"
    ManagedBy   = "Terraform"
  }
}

resource "aws_instance" "private" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private.id]

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8
  }

  tags = {
    Name        = "BonTech-Terraform-Private-Server"
    Environment = "Security-Lab"
    ManagedBy   = "Terraform"
  }
}
