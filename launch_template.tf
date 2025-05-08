# Create IAM Instance Profile that references the existing ECS Instance Role
data "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile"
 // role = data.aws_iam_role.ecs_instance_role.name
}

/*
# Data source to get the existing ECS Instance Role
data "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole"  # Replace with your existing ECS instance role name
}
*/

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
