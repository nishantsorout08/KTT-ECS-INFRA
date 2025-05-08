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