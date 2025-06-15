# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

# Load Balancer Outputs
output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

# RDS Outputs
output "mysql_endpoint" {
  description = "MySQL RDS instance endpoint"
  value       = aws_db_instance.mysql.endpoint
}

output "mysql_port" {
  description = "MySQL RDS instance port"
  value       = aws_db_instance.mysql.port
}

output "postgres_endpoint" {
  description = "PostgreSQL RDS instance endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "postgres_port" {
  description = "PostgreSQL RDS instance port"
  value       = aws_db_instance.postgres.port
}

# Auto Scaling Group Outputs
output "react_app_asg_name" {
  description = "Name of the React App Auto Scaling Group"
  value       = aws_autoscaling_group.react_app_asg.name
}

output "bi_tool_asg_name" {
  description = "Name of the BI Tool Auto Scaling Group"
  value       = aws_autoscaling_group.bi_tool_asg.name
}

# Security Group Outputs
output "ec2_security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "mysql_security_group_id" {
  description = "ID of the MySQL security group"
  value       = aws_security_group.rds_mysql.id
}

output "postgres_security_group_id" {
  description = "ID of the PostgreSQL security group"
  value       = aws_security_group.rds_postgres.id
}

# Domain and SSL Outputs
output "domain_name" {
  description = "Domain name for the application"
  value       = var.domain_name
}

output "app_url" {
  description = "URL for the main application"
  value       = "https://haseeb-app.${var.domain_name}"
}

output "bi_url" {
  description = "URL for the BI tool"
  value       = "https://haseeb-bi.${var.domain_name}"
}

output "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

# Target Group Outputs
output "react_app_target_group_arn" {
  description = "ARN of the React App Target Group"
  value       = aws_lb_target_group.react_app_tg.arn
}

output "bi_tool_target_group_arn" {
  description = "ARN of the BI Tool Target Group"
  value       = aws_lb_target_group.bi_tool_tg.arn
}

# Database Connection Information
output "database_connection_info" {
  description = "Database connection information for SSH tunneling"
  value = {
    mysql = {
      host     = aws_db_instance.mysql.endpoint
      port     = aws_db_instance.mysql.port
      database = aws_db_instance.mysql.db_name
      username = aws_db_instance.mysql.username
    }
    postgres = {
      host     = aws_db_instance.postgres.endpoint
      port     = aws_db_instance.postgres.port
      database = aws_db_instance.postgres.db_name
      username = aws_db_instance.postgres.username
    }
  }
  sensitive = true
}