output "ec2_ipv6_address" {
  description = "The IPv6 address of the EC2 instance"
  value       = module.ec2_instance.ipv6_addresses[0]
}
