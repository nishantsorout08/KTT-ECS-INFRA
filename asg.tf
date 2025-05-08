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