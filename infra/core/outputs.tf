output "ec2_ipv6_address" {
  description = "The IPv6 address of the EC2 instance (attached via static ENI)"
  value       = tolist(aws_network_interface.web.ipv6_addresses)[0]
}
