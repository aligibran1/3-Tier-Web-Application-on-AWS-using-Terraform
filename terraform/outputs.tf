output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.compute.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.compute.alb_arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.compute.asg_name
}

output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = module.database.rds_endpoint
  sensitive   = true
}

output "rds_database_name" {
  description = "Name of the RDS database"
  value       = module.database.database_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnets" {
  description = "List of private application subnet IDs"
  value       = module.vpc.private_app_subnet_ids
}

output "private_db_subnets" {
  description = "List of private database subnet IDs"
  value       = module.vpc.private_db_subnet_ids
}
