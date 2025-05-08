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

    depends_on = [
    aws_ecs_task_definition.auth_task,
    aws_ecs_capacity_provider.ktt_cp,
    aws_lb_listener_rule.auth_rule
  ]
  
  force_new_deployment = true

  deployment_controller {
    type = "ECS"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.auth_tg.arn
    container_name   = "backend-auth-container"
    container_port   = 8080
  }
 
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ktt_cp.name
    weight            = 1
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

  depends_on = [
    aws_ecs_task_definition.booking_task,
    aws_ecs_capacity_provider.ktt_cp,
    aws_lb_listener_rule.booking_rule
  ]

  force_new_deployment = true

  deployment_controller {
    type = "ECS"
  }
  

  load_balancer {
    target_group_arn = aws_lb_target_group.booking_tg.arn
    container_name   = "backend-booking-container"
    container_port   = 8082
  }


  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ktt_cp.name
    weight            = 1
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

    depends_on = [
    aws_ecs_task_definition.admin_task,
    aws_ecs_capacity_provider.ktt_cp,
    aws_lb_listener_rule.admin_rule
  ]
  
  force_new_deployment = true

  deployment_controller {
    type = "ECS"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.admin_tg.arn
    container_name   = "backend-admin-container"
    container_port   = 9002
  }
 
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ktt_cp.name
    weight            = 1
  }

  iam_role = data.aws_iam_role.ecs_service_role.arn  # Reference existing role

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
}