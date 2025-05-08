output "ecr_repositories" {
  value = {
    backend_auth = aws_ecr_repository.backend_auth.repository_url
    backend_booking = aws_ecr_repository.backend_booking.repository_url
     backend_admin = aws_ecr_repository.backend_admin.repository_url
  }
}

output "image_tag" {
  description = "The Git commit hash used as the image tag"
  value       = var.image_tag
}

output "docker_push_commands" {
  value = <<EOT
# 1️⃣ Authenticate Docker with ECR
aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.backend_auth.repository_url}

# 2️⃣ Tag and Push Docker Images

# Backend Authentication:
docker tag backend-auth-image:latest ${aws_ecr_repository.backend_auth.repository_url}:$TAG
docker push ${aws_ecr_repository.backend_auth.repository_url}:$TAG

# Backend Booking:
docker tag backend-booking-image:latest ${aws_ecr_repository.backend_booking.repository_url}:$TAG
docker push ${aws_ecr_repository.backend_booking.repository_url}:$TAG

# Backend Admin:
docker tag backend-admin-image:latest ${aws_ecr_repository.backend_admin.repository_url}:$TAG
docker push ${aws_ecr_repository.backend_admin.repository_url}:$TAG

EOT
}