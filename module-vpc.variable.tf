#############################################
variables of module vpc
#############################################
variable "vpc_cidr" {}
variable "project" {
default ="demo"
}
variable "environment" {
default = "demo"
}
variable "subnet" {}
