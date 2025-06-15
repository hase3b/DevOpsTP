data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch Template for React App
resource "aws_launch_template" "react_app" {
  name_prefix   = "${var.project_name}-react-app-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = base64encode(templatefile("${path.module}/userapp_data.sh", {
    domain_name = var.domain_name,
    dockerfile_content = file("${path.module}/Dockerfile-app")
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-react-app-instance"
      Role = "react-app"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Launch Template for BI Tool
resource "aws_launch_template" "bi_tool" {
  name_prefix   = "${var.project_name}-bi-tool-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = base64encode(templatefile("${path.module}/userbi_data.sh", {
  domain_name = var.domain_name
  }))
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-bi-tool-instance"
      Role = "bi-tool"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for React App
resource "aws_autoscaling_group" "react_app_asg" {
  name                = "${var.project_name}-react-app-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.react_app_tg.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_size_app
  max_size         = var.max_size_app
  desired_capacity = var.desired_capacity_app

  launch_template {
    id      = aws_launch_template.react_app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-react-app-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for BI Tool
resource "aws_autoscaling_group" "bi_tool_asg" {
  name                = "${var.project_name}-bi-tool-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.bi_tool_tg.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_size_bi 
  max_size         = var.max_size_bi
  desired_capacity = var.desired_capacity_bi

  launch_template {
    id      = aws_launch_template.bi_tool.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-bi-tool-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Policies (for React App ASG)
resource "aws_autoscaling_policy" "react_app_scale_up" {
  name                   = "${var.project_name}-react-app-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.react_app_asg.name
}

resource "aws_autoscaling_policy" "react_app_scale_down" {
  name                   = "${var.project_name}-react-app-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.react_app_asg.name
}

# CloudWatch Alarms (for React App ASG)
resource "aws_cloudwatch_metric_alarm" "react_app_cpu_high" {
  alarm_name          = "${var.project_name}-react-app-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors react app ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.react_app_scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.react_app_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "react_app_cpu_low" {
  alarm_name          = "${var.project_name}-react-app-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors react app ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.react_app_scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.react_app_asg.name
  }
}