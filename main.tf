##################################################
# Created module for vpc
##################################################

Mkdir /var/modules/vpc/

##################################################
# Create vpc
##################################################

resource "aws_vpc" "project" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"
  tags = {
    Name = "${var.project}-${var.environment}"
  }
}

###################################################
# Create Internet gateway
###################################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.project.id
  tags = {
    Name = "${var.project}-${var.environment}"
  }
}

###################################################
# Create 3 private subnet
###################################################

resource "aws_subnet" "private" {
  count                   = var.subnet
  vpc_id                  = aws_vpc.project.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 3, var.subnet + count.index)
  availability_zone       = data.aws_availability_zones.az.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project}-${var.environment}-private-${count.index}"
  }
}

#####################################################
# Create 3 public subnet
#####################################################
resource "aws_subnet" "public" {
  count                   = var.subnet
  vpc_id                  = aws_vpc.project.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 3, count.index)
  availability_zone       = data.aws_availability_zones.az.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project}-${var.environment}-public-${count.index}"
  }
}

######################################################
# Create public route able
######################################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.project.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

#######################################################
# Create public route table association for public subnet
########################################################
resource "aws_route_table_association" "public_subnet" {
  count          = var.subnet
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
########################################################
# Create Elastic IP
########################################################

resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "${var.project}-${var.environment}-nat"
  }
}

#######################################################
# Create nat gateway
#######################################################
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[1].id

  tags = {
    Name = "${var.project}-${var.environment}-nat"
  }
  depends_on = [aws_internet_gateway.igw]
}

#####################################################
# Create private route table
#####################################################

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.project.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "${var.project}-${var.environment}-private"
  }
}

#####################################################
# Create route table association for private subnet
#####################################################

resource "aws_route_table_association" "private_subnet" {
  count          = var.subnet
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

