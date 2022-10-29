###################################################
# Create Variables
###################################################

variable "aws_region" {}
variable "aws_access-key" {}
variable "aws_secret-key" {}
variable "project_vpc_cidr" {}
variable "project_subnet" {}
variable "project_name" {}
variable "project_environment" {}
variable "frontend-webaccess-ports" {
  description = "port for frontend security groups"
  type        = set(string)
}
locals {
  common_tags = {
    project     = var.project_name
    environment = var.project_environment
  }
}
variable "instance_ami" {}
variable "main-domain" {}
variable "localhost" {}
