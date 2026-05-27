output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.grocery_app.public_ip
}

output "rds_endpoint" {
  description = "RDS connection endpoint"
  value       = aws_db_instance.grocery_db.endpoint
}