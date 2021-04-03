# application load balancer
resource "aws_lb" "keg_alb" {
  name                       = "keg-deploy-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.keg_sg_public.id]
  subnets                    = [aws_subnet.keg_public_subnet.id, aws_subnet.keg_private_subnet.id]
  enable_deletion_protection = false

  tags = {
    "Name" = "Keg Deploy - App LB"
  }
}

# listener for http traffic
resource "aws_lb_listener" "keg_http_listener" {
  load_balancer_arn = aws_lb.keg_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      host        = "#{host}"
      path        = "/#{path}"
      port        = "443"
      protocol    = "HTTPS"
      query       = "#{query}"
      status_code = "HTTP_301"
    }
  }
}

# listener for https traffic
resource "aws_lb_listener" "keg_https_listener" {
  load_balancer_arn = aws_lb.keg_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.aws_ssl_cert_id

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.keg_target_group.arn
  }
}