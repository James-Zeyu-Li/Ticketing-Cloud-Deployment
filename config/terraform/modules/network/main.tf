# Create a dedicated VPC for the ticketing application
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.service_name}-vpc"
  }
}

data "aws_availability_zones" "available" {}

locals {
  # Select AZs up to the number of CIDRs provided (default first two AZs)
  selected_azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, max(length(var.public_subnet_cidrs), length(var.private_subnet_cidrs)))
}

# Public subnets (hosts ALB and NAT Gateway)
resource "aws_subnet" "public" {
  for_each                = { for idx, cidr in var.public_subnet_cidrs : idx => cidr }
  cidr_block              = each.value
  vpc_id                  = aws_vpc.this.id
  availability_zone       = element(local.selected_azs, each.key)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.service_name}-public-subnet-${each.key}"
  }
}

# Private subnets (hosts ECS, RDS, Redis, etc.)
resource "aws_subnet" "private" {
  for_each                = { for idx, cidr in var.private_subnet_cidrs : idx => cidr }
  cidr_block              = each.value
  vpc_id                  = aws_vpc.this.id
  availability_zone       = element(local.selected_azs, each.key)
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.service_name}-private-subnet-${each.key}"
  }
}

# Internet Gateway for public subnet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.service_name}-igw"
  }
}

# Public route table -> Internet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway in the first public subnet to allow private subnet internet egress
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.service_name}-nat"
  }
}

# Private route table -> NAT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# ====== ALB Security Group =====
resource "aws_security_group" "alb_sg" {
  name   = "${var.service_name}-alb-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = var.alb_port
    to_port     = var.alb_port
    protocol    = "tcp"
    cidr_blocks = length(var.cidr_blocks) > 0 ? var.cidr_blocks : ["0.0.0.0/0"]
    description = "Allow public traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.service_name}-alb-sg"
  }
}



# ====== ECS Security Group =====
# Create Security Group for ECS Tasks

resource "aws_security_group" "this" {
  name        = "${var.service_name}-ecs-sg"
  description = "Allow inbound traffic on ${var.container_port}"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Update to access from ALB only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.service_name}-ecs-sg"
  }
}


# ====== RDS Security Group =====
resource "aws_security_group" "rds_sg" {
  name   = "${var.service_name}-rds-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    security_groups = [aws_security_group.this.id]
    description     = "RDS only allow access from ECS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.service_name}-rds-sg"
  }
}

# ====== Redis Security Group =====
resource "aws_security_group" "redis_sg" {
  name   = "${var.service_name}-redis-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    from_port       = var.redis_port
    to_port         = var.redis_port
    protocol        = "tcp"
    security_groups = [aws_security_group.this.id]
    description     = "Redis only allow access from ECS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.service_name}-redis-sg"
  }
}

