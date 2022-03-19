output "security_group_id" {
  value       = aws_security_group.this.id
  description = "ID of the security group assigned to the bastion host."
}
