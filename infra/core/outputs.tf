output "ec2_public_ipv4_address" {
  description = "The static public IPv4 address (Elastic IP) of the EC2 instance"
  value       = aws_eip.web.public_ip
}
