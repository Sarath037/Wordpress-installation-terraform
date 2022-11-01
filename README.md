Installing wordpress using terraform
==========================================

Terraform is a tool for building infrastructure with various technologies including Amazon AWS, Microsoft Azure, Google Cloud, and vSphere. Here is a simple document on how to use Terraform to install wordpress simply.

Use the following command to install Terraform
=============================================
```sh

wget https://releases.hashicorp.com/terraform/0.15.3/terraform_0.15.3_linux_amd64.zip
unzip terraform_0.15.3_linux_amd64.zip 
ls -l
-rwxr-xr-x 1 root root 79991413 oct  6 18:03 terraform  <<=======
-rw-r--r-- 1 root root 32743141 oct  6 18:50 terraform_0.15.3_linux_amd64.zip
mv terraform /usr/bin/
which terraform 
/usr/bin/terraform
```

 Create a module directory for vpc
=============================================
```sh

Mkdir /var/modules/vpc/
```

Create vpc resource under module directory
=============================================
```sh

resource "aws_vpc" "project" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"
  tags = {
    Name = "${var.project}-${var.environment}"
  }
}

```
 Create Internet gateway
=============================================
```sh

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.project.id
  tags = {
    Name = "${var.project}-${var.environment}"
  }
}

```
Create 3 private subnet group
=============================================
```sh

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
```

Create 3 public subnet group
=============================================
```sh

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
```

 Create public route able
=============================================
```sh

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.project.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

```
Create public route table association for public subnet
=============================================
```sh
resource "aws_route_table_association" "public_subnet" {
  count          = var.subnet
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

```
Create Elastic IP address
=============================================
```sh
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "${var.project}-${var.environment}-nat"
  }
}
```
Create nat gateway
=============================================
```sh
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[1].id

  tags = {
    Name = "${var.project}-${var.environment}-nat"
  }
  depends_on = [aws_internet_gateway.igw]
}

```
Create private route table
=============================================
```sh

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
```
Create route table association for private subnet
=============================================
```sh

resource "aws_route_table_association" "private_subnet" {
  count          = var.subnet
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
```

variables of module vpc
=============================================
```sh
variable "vpc_cidr" {}
variable "project" {
default ="demo"
}
variable "environment" {
default = "demo"
}
variable "subnet" {}

```

# output result of vpc and subnet id's
=============================================
```sh
output "vpc_id" {
  value = aws_vpc.project.id
}
output "public1_id" {
  value = aws_subnet.public[0].id
}
output "public2_id" {
  value = aws_subnet.public[1].id
}
output "public3_id" {
  value = aws_subnet.public[2].id
}
output "private1_id" {
  value = aws_subnet.private[0].id
}
output "private2_id" {
  value = aws_subnet.private[1].id
}
output "private3_id" {
  value = aws_subnet.private[2].id
}

output "public" {
  value = aws_subnet.public[*].id
}
output "private_id" {
  value = aws_subnet.private[*].id
}

```
