variable "aws_region" {
  default = "ap-south-1"
}

variable "image_tag" {
  description = "The image tag for the Docker image"
  type        = string
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
  default     = "ktt-cluster"
}

variable "vpc_id" {
default = "vpc-0040321d1cdc2e010"
}

variable "subnet_ids" {
  type = list(string)
default =  ["subnet-058a9db7f15b08540","subnet-00655a6224c447235"] # ("subnet-0e3daa9422adb8ec2" instance type (t2.small) is not supported in your requested Availability Zone (ap-south-1c))

}

variable "alb_security_group" {
default = "sg-0e3a6cfdb67d677f8"
}

variable "ecs_instance_security_group" {
default = "sg-0e3a6cfdb67d677f8"
}

variable "key_name" {
default = "dev-server"
}


variable "ami_image_id" {
  description = "The AMI ID to use for EC2 instances in the ECS cluster"
  type        = string
  default = "ami-0b14bc68238a38fbd"
}

variable "instance_type" {
  type = string
  default = "t2.medium"
}

