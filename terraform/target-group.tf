# target group for the application load balancer
resource "aws_lb_target_group" "keg_target_group" {
  name       = "keg-target-group"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = aws_vpc.keg_vpc.id
  slow_start = 30

  health_check {
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
    matcher             = "200-299"
    # keg-proxy's traefik healthcheck endpoint at 8080/ping
    port = var.health_check_port
    path = var.health_check_path
  }
}

# register the ec2 instance with the target group
resource "aws_lb_target_group_attachment" "keg-target-group-att" {
  target_group_arn = aws_lb_target_group.keg_target_group.arn
  target_id        = aws_instance.keg_app.id
  port             = var.target_group_port
}