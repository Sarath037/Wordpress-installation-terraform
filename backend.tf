#################################
# Fetch vpc contents from module
#################################
module "vpc" {

  source      = "/var/modules/vpc"
  vpc_cidr    = var.project_vpc_cidr
  subnet      = var.project_subnet
  project     = var.project_name
  environment = var.project_environment
}

##################################################
# bastion server
##################################################

resource "aws_instance" "bastion" {

  ami                    = var.instance_ami
  instance_type          = "t2.micro"
  key_name               = "Webserver"
  subnet_id              = module.vpc.public2_id
  vpc_security_group_ids = [module.sg-bastion.sg_id]
  tags = {
    Name = "${var.project_name}-${var.project_environment}-bastion"
  }

}

##################################################
# Template file to fetch backend server details
##################################################
data "template_file" "script" {
  template = file("${path.module}/userdata-db.sh.tbl")
  vars = {
    DB_PASSWD = "wordpress"
  }
}
output "script_content" {
  value = data.template_file.script.rendered
}

##################################################
# Instance for database creation
##################################################
resource "aws_instance" "database" {
  ami                    = var.instance_ami
  instance_type          = "t2.micro"
  key_name               = "frontandback"
  subnet_id              = module.vpc.private1_id
  vpc_security_group_ids = [module.sg-backend.sg_id]
  user_data              = data.template_file.script.rendered
  tags = {
    Name = "${var.project_name}-${var.project_environment}-dbserver"
  }
  lifecycle {
    create_before_destroy = true
  }
}

##################################################
# bastion security group
##################################################
module "sg-bastion" {

  source         = "/var/modules/sg"
  project        = var.project_name
  environment    = var.project_environment
  sg_name        = "bastion"
  sg_description = "bastion security group"
  sg_vpc         = module.vpc.vpc_id
}

resource "aws_security_group_rule" "bastion" {
  type              = "ingress"
  from_port         = "22"
  to_port           = "22"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.sg-bastion.sg_id
}

##################################################
# bastion security group
##################################################

module "sg-frontend" {

  source         = "/var/modules/sg"
  project        = var.project_name
  environment    = var.project_environment
  sg_name        = "frontend"
  sg_description = "frondend security group"
  sg_vpc         = module.vpc.vpc_id
}
resource "aws_security_group_rule" "frontend-web-access" {

  for_each          = var.frontend-webaccess-ports
  type              = "ingress"
  from_port         = each.key
  to_port           = each.key
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = module.sg-frontend.sg_id
}

resource "aws_security_group_rule" "frontend-remote-access" {

  type                     = "ingress"
  from_port                = "22"
  to_port                  = "22"
  protocol                 = "tcp"
  source_security_group_id = module.sg-bastion.sg_id
  security_group_id        = module.sg-frontend.sg_id
}

##################################################
# backend security group
##################################################
module "sg-backend" {

  source         = "/var/modules/sg"
  project        = var.project_name
  environment    = var.project_environment
  sg_name        = "backend"
  sg_description = "backend security group"
  sg_vpc         = module.vpc.vpc_id
}
resource "aws_security_group_rule" "backend-ssh-access" {

  type                     = "ingress"
  from_port                = "22"
  to_port                  = "22"
  protocol                 = "tcp"
  source_security_group_id = module.sg-bastion.sg_id
  security_group_id        = module.sg-backend.sg_id
}

resource "aws_security_group_rule" "backend-db-access" {

  type                     = "ingress"
  from_port                = "3306"
  to_port                  = "3306"
  protocol                 = "tcp"
  source_security_group_id = module.sg-frontend.sg_id
  security_group_id        = module.sg-backend.sg_id

}

##################################################
# A record creation for the website 
##################################################

data "aws_route53_zone" "dns" {
  name         = var.main-domain
  private_zone = false
}

resource "aws_route53_record" "wordpress" {
  zone_id = data.aws_route53_zone.dns.zone_id
  name    = "wordpress"
  type    = "A"
  ttl     = "3"
  records = [aws_instance.webserver.public_ip]
}

