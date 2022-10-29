####################################################
# Created template for fetching userdata of webserver
####################################################
data "template_file" "script1" {
  template = file("${path.module}/userdata-wp.sh.tbl")
  vars = {
    db_user     = "wordpress"
    db_passwd   = "wordpress"
    db_database = "wordpress"
    LocalHost   = var.localhost
  }
}
output "web" {
value = data.template_file.script1.rendered
}
#########################################################################
# Created instance for wordpress webserver after creating database instance
##########################################################################

resource "aws_instance" "webserver" {
  ami                    = var.instance_ami
  instance_type          = "t2.micro"
  key_name               = "frontandback"
  subnet_id              = module.vpc.public1_id
  vpc_security_group_ids = [module.sg-frontend.sg_id]
  user_data              = data.template_file.script1.rendered
  tags = {
    Name = "${var.project_name}-${var.project_environment}-webserver"
  }
  depends_on = [aws_instance.database]
  lifecycle {
    create_before_destroy = true
  }
}
