output "vpc_id" {
  description = "ID of the lab VPC."
  value       = aws_vpc.bontech.id
}

output "public_instance_public_ip" {
  description = "Dynamically assigned public IPv4 address of the bastion/web server."
  value       = aws_instance.public.public_ip
}

output "public_instance_private_ip" {
  description = "Private IPv4 address of the public server."
  value       = aws_instance.public.private_ip
}

output "private_instance_private_ip" {
  description = "Private IPv4 address of the private server."
  value       = aws_instance.private.private_ip
}

output "nat_gateway_public_ip" {
  description = "Elastic IP used by the NAT Gateway for private outbound traffic."
  value       = aws_eip.nat.public_ip
}
