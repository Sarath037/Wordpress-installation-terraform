#######################################
# output result of vpc and subnet id's
########################################
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

