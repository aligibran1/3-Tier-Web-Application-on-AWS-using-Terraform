output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "EC2 Security Group ID"
  value       = aws_security_group.ec2.id
}

output "db_security_group_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}

output "ec2_iam_instance_profile" {
  description = "IAM Instance Profile for EC2"
  value       = aws_iam_instance_profile.ec2_profile.name
}
