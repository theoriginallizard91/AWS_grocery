provider "aws" {
  region = var.aws_region
}

# Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  name        = "grocery-ec2-sg"
  description = "Security group for grocery app EC2 instance"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "grocery-rds-sg"
  description = "Security group for grocery app RDS instance"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "grocery_app" {
  ami           = var.ec2_ami
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "grocery-app-server"
  }
}

# RDS Instance
resource "aws_db_instance" "grocery_db" {
  identifier        = "grocery-db"
  engine            = "postgres"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password

  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot = true

  tags = {
    Name = "grocery-db"
  }
}
# Application Load Balancer
resource "aws_lb" "grocery_alb" {
  name               = "myloadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_sg.id]
  subnets            = ["subnet-08cac010186510c24", "subnet-06c3d1ed97f98f73a"]

  tags = {
    Name = "grocery-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "grocery_tg" {
  name     = "firsttargetgroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0ead8cb1f8f26ff71"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener
resource "aws_lb_listener" "grocery_listener" {
  load_balancer_arn = aws_lb.grocery_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grocery_tg.arn
  }
}

# Launch Template for Auto Scaling
resource "aws_launch_template" "grocery_lt" {
  name_prefix   = "grocery-launch-template"
  image_id      = "ami-0de6934e87badb694"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "grocery-launch-template"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "grocery_asg" {
  name                = "grocery-asg"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1
  target_group_arns   = [aws_lb_target_group.grocery_tg.arn]
  vpc_zone_identifier = ["subnet-08cac010186510c24", "subnet-06c3d1ed97f98f73a"]

  launch_template {
    id      = aws_launch_template.grocery_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "grocery-asg-instance"
    propagate_at_launch = true
  }
}