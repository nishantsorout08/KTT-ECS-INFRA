#-----------------Provider---------------------------
provider "aws" {
  region = var.aws_region
}


#----------------------Application Load balancer--------------------
# Create Application Load Balancer (ALB)
resource "aws_lb" "ktt_ecs_alb" {
  name               = "ktt-ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group]
  subnets            = var.subnet_ids
  enable_deletion_protection = false
}

# Create Target Group for Authentication Service
resource "aws_lb_target_group" "auth_tg" {
  name        = "ktt-auth-tg"
  port        = 8080          #port for listening auth service
  protocol    = "HTTP" 
  vpc_id      = var.vpc_id
  target_type = "instance"  

  health_check {
    path                = "/"  
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher  = "200-499"
  }

}

# Create Target Group for Booking Service
resource "aws_lb_target_group" "booking_tg" {
  name        = "ktt-booking-tg"
  port        = 8082             #port for listening booking service
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"  

  health_check {
    path                = "/" 
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher  = "200-499"
  }
}

# Create Target Group for Admin Service
resource "aws_lb_target_group" "admin_tg" {
  name        = "ktt-admin-tg"
  port        = 9002             #port for listening booking service
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"  

  health_check {
    path                = "/" 
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher  = "200-499"
  }
}

# ALB HTTP Listener (Port 443)
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.ktt_ecs_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = "arn:aws:acm:ap-south-1:288761766643:certificate/b767719b-1cb9-4449-8579-44ce0d5823fd"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Service not found"
      status_code  = "404"
    }
  }
}

# Highest priority: Health checks (if needed)
resource "aws_lb_listener_rule" "health_check" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 50  # Lower number = higher priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth_tg.arn  # Or a dedicated health-check TG
  }

  condition {
    path_pattern {
      values = ["/health"]  # Ensure health checks pass
    }
  }
}

# Auth service (priority 100)
resource "aws_lb_listener_rule" "auth_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/api/v1/auth*", "/api/v1/auth/*", "/*"]  # Handles all /auth/* and /api/v1/auth/* and /*
    }
  }
}

# Booking service (priority 200)
resource "aws_lb_listener_rule" "booking_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.booking_tg.arn
  }

  condition {
    path_pattern {
      values = ["/booking*", "/booking/*", "/*"] # Handles all /booking/* and /*
    }
  }
}

# Admin service (priority 300)
resource "aws_lb_listener_rule" "admin_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.admin_tg.arn
  }

  condition {
    path_pattern {
      values = ["/admin*", "/admin/*", "/*"] # Handles all /admin/* and /*
    }
  }
}

# Default rule (lowest priority)
resource "aws_lb_listener_rule" "default_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 500  # Lowest priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth_tg.arn  # Or a static site TG
  }

  # Catch-all for unmatched paths
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}



#------------------------------Auto-Scaling Group--------------------------------
resource "aws_autoscaling_group" "ecs_asg" {
  name 		       = "ktt-ecs-asg"
  min_size             = 1
  desired_capacity     = 1  # make it 0 while scheduling the servers
  max_size             = 5
  
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "ktt-AutoScaling-Instance"
    propagate_at_launch = true
  }
}

/*
# Start EC2 Mon–Fri at 10:30 AM IST (05:00 UTC)
resource "aws_autoscaling_schedule" "start_instance_in_morning" {
  scheduled_action_name  = "start-ec2-morning"
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.name
  min_size             = 0
  desired_capacity     = 1
  max_size             = 5
  recurrence           = "30 4 * * 1-5"  # Mon–Fri only
}

# Stop EC2 Mon-Fri at 7:30 PM IST (14:00 UTC)
resource "aws_autoscaling_schedule" "stop_instance_in_evening" {
  scheduled_action_name  = "stop-ec2-evening"
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.name
  min_size             = 0
  desired_capacity     = 0
  max_size             = 5
  recurrence              = "00 14 * * *"  # 14:00 UTC daily
}

# Safety: Stop EC2 on Sat at 6 AM IST (00:30 UTC)
resource "aws_autoscaling_schedule" "weekend_shutdown_saturday" {
  scheduled_action_name  = "stop-ec2-saturday"
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.name
  min_size             = 0
  desired_capacity     = 0
  max_size             = 5
  recurrence           = "30 0 * * 6"  # Saturday
}

# Safety: Stop EC2 on Sun at 6 AM IST (00:30 UTC)
resource "aws_autoscaling_schedule" "weekend_shutdown_sunday" {
  scheduled_action_name  = "stop-ec2-sunday"
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.name
  min_size             = 0
  desired_capacity     = 0
  max_size             = 5
  recurrence           = "30 0 * * 0"  # Sunday
}
*/




#-----------------------------Auto-Scaling Policy------------------------------
resource "aws_autoscaling_policy" "ecs_scale_up" {
  name                   = "ecs-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 60  #seconds
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.name
}

resource "aws_autoscaling_policy" "ecs_scale_down" {
  name                   = "ecs-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 60  #seconds
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = 60
  statistic          = "Average"
  threshold          = 70
  alarm_actions      = [aws_autoscaling_policy.ecs_scale_up.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ecs_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "ecs-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = 60
  statistic          = "Average"
  threshold          = 30
  alarm_actions      = [aws_autoscaling_policy.ecs_scale_down.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ecs_asg.name
  }
}




#--------------------------------Launch-Template----------------------------
#Create IAM Instance Profile that references the existing ECS Instance Role
data "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile"
 }

resource "aws_launch_template" "ecs_launch_template" {
  name = "ecs-launch-template"

  image_id      = var.ami_image_id  # Amazon ECS-Optimized AMI
  instance_type = var.instance_type
  key_name      = var.key_name
  
  iam_instance_profile {
    name = data.aws_iam_instance_profile.ecs_instance_profile.name
  }

 block_device_mappings {
    device_name = "/dev/xvda" # default root volume
    ebs {
      volume_size           = 8
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      delete_on_termination = true
    }
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.ecs_instance_security_group]
  }

user_data = base64encode(<<-EOF
#!/bin/bash
exec > /tmp/user_data.log 2>&1
set -x
# Configure ECS cluster name
echo "ECS_CLUSTER=ktt-cluster" | sudo tee -a /etc/ecs/ecs.config
EOF
)
}



#--------------------------------------ECR-------------------------------
resource "aws_ecr_repository" "backend_auth" {
  name = "ktt-backend-auth"
 
  image_tag_mutability = "IMMUTABLE"  # Prevents overwriting image tags
 
image_scanning_configuration {
    scan_on_push = true
  }
 
  tags = {
    Environment = "ktt"
  }
}

resource "aws_ecr_repository" "backend_booking" {
  name = "ktt-backend-booking"
 
  image_tag_mutability = "IMMUTABLE"  # Prevents overwriting image tags
 
image_scanning_configuration {
    scan_on_push = true
  }
 
  tags = {
    Environment = "ktt"
  }
}

resource "aws_ecr_repository" "backend_admin" {
  name = "ktt-backend-admin"
 
  image_tag_mutability = "IMMUTABLE"  # Prevents overwriting image tags
 
image_scanning_configuration {
    scan_on_push = true
  }
 
  tags = {
    Environment = "ktt"
  }
}


resource "aws_ecr_lifecycle_policy" "auth_cleanup" {
  repository = aws_ecr_repository.backend_auth.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "booking_cleanup" {
  repository = aws_ecr_repository.backend_booking.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "admin_cleanup" {
  repository = aws_ecr_repository.backend_admin.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}




#-----------------------------ECS-custer------------------------------------------
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name
}



#-------------------------------ECS-Service------------------------------------------------
# Reference the existing IAM role
data "aws_iam_role" "ecs_service_role" {
  name = "AWSServiceRoleForECS"
}

# ECS Service for Auth Service
resource "aws_ecs_service" "backend_auth_service" {
  name            = "backend-auth-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.auth_task.arn
  desired_count   = 1
  launch_type     = "EC2"
    depends_on = [
    aws_lb_listener_rule.auth_rule
  ]
  
  force_new_deployment = true

  deployment_controller {
    type = "ECS"
  }

 health_check_grace_period_seconds = 600  # gives ecs-service a grace time to warm up spring boot 

  load_balancer {
    target_group_arn = aws_lb_target_group.auth_tg.arn
    container_name   = "backend-auth-container"
    container_port   = 8080
  }
  iam_role = data.aws_iam_role.ecs_service_role.arn  # Reference existing role

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
}

# ECS Service for Booking Service
resource "aws_ecs_service" "backend_booking_service" {
  name            = "backend-booking-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.booking_task.arn
  desired_count   = 1
  launch_type     = "EC2"
  depends_on = [
    aws_lb_listener_rule.booking_rule
  ]

  force_new_deployment = true

  deployment_controller {
    type = "ECS"
  }
  
 health_check_grace_period_seconds = 600  # gives ecs-service a grace time to warm up spring boot 

  load_balancer {
    target_group_arn = aws_lb_target_group.booking_tg.arn
    container_name   = "backend-booking-container"
    container_port   = 8082
  }

  iam_role = data.aws_iam_role.ecs_service_role.arn  # Reference existing role

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
}

# ECS Service for Admin Service
resource "aws_ecs_service" "backend_admin_service" {
  name            = "backend-admin-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.admin_task.arn
  desired_count   = 1
  launch_type     = "EC2"
    depends_on = [
    aws_lb_listener_rule.admin_rule
  ]
  
  force_new_deployment = true

  deployment_controller {
    type = "ECS"
  }

 health_check_grace_period_seconds = 600  # gives ecs-service a grace time to warm up spring boot 

  load_balancer {
    target_group_arn = aws_lb_target_group.admin_tg.arn
    container_name   = "backend-admin-container"
    container_port   = 9002
  }
  iam_role = data.aws_iam_role.ecs_service_role.arn  # Reference existing role

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
}




#---------------------------------ECS-tasks---------------------------------------------------
# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/ktt-service-logs"
}


# IAM Role 
data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

# ECS Task Definition for Auth Service
resource "aws_ecs_task_definition" "auth_task" {
  family                   = "backend-auth-task"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = data.aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "backend-auth-container"
    image     = "${aws_ecr_repository.backend_auth.repository_url}:${var.image_tag}"  # immutable tag
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [
      {
        containerPort = 8080
        hostPort      = 0
      }
    ],

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/ktt-service-logs"
        "awslogs-region"        = "ap-south-1"
        "awslogs-stream-prefix" = "auth"
      }
    }
  }])
}

# ECS Task Definition for Booking Service
resource "aws_ecs_task_definition" "booking_task" {
  family                   = "backend-booking-task"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = data.aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "512"
  memory                   = "1024"

  container_definitions = jsonencode([{
    name      = "backend-booking-container"
    image     = "${aws_ecr_repository.backend_booking.repository_url}:${var.image_tag}" # immutable tag
    cpu       = 512
    memory    = 1024
    essential = true
    portMappings = [
      {
        containerPort = 8082
        hostPort      = 0
      }
    ],

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/ktt-service-logs"
        "awslogs-region"        = "ap-south-1"
        "awslogs-stream-prefix" = "booking"
      }
    }
  }])
}

# ECS Task Definition for Admin Service
resource "aws_ecs_task_definition" "admin_task" {
  family                   = "backend-admin-task"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = data.aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "backend-admin-container"
    image     = "${aws_ecr_repository.backend_admin.repository_url}:${var.image_tag}"  # immutable tag
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [
      {
        containerPort = 9002
        hostPort      = 0
      }
    ],

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/ktt-service-logs"
        "awslogs-region"        = "ap-south-1"
        "awslogs-stream-prefix" = "admin"
      }
    }
  }])
}

