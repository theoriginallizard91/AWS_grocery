variable "aws_region" {
  description = "AWS region"
  default     = "eu-central-1"
}

variable "ec2_ami" {
  description = "AMI ID for EC2 instance"
  default     = "ami-0de6934e87badb694"
}

variable "db_name" {
  description = "Database name"
  default     = "grocerydb"
}

variable "db_username" {
  description = "Database username"
  default     = "postgres"
}

variable "db_password" {
  description = "Database password"
  sensitive   = true
}