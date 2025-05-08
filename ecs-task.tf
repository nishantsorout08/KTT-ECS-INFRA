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