Installing wordpress using terraform
==========================================

Terraform is a tool for building infrastructure with various technologies including Amazon AWS, Microsoft Azure, Google Cloud, and vSphere. Here is a simple document on how to use Terraform to install wordpress simply.

Use the following command to install Terraform
=============================================

wget https://releases.hashicorp.com/terraform/0.15.3/terraform_0.15.3_linux_amd64.zip
unzip terraform_0.15.3_linux_amd64.zip 
ls -l
-rwxr-xr-x 1 root root 79991413 oct  6 18:03 terraform  <<=======
-rw-r--r-- 1 root root 32743141 oct  6 18:50 terraform_0.15.3_linux_amd64.zip
mv terraform /usr/bin/
which terraform 
/usr/bin/terraform
