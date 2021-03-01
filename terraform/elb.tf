resource "aws_elb" "keg_elb" {
  name                      = "keg-deploy-elb"
  instances                 = [aws_instance.keg_app.id]
  subnets                   = [aws_subnet.keg_public_subnet.id, aws_subnet.keg_private_subnet.id]
  cross_zone_load_balancing = true

  listener {
    instance_port     = 80
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  health_check {
    target              = "HTTP:80/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name = "Keg Deploy - ELB"
  }
}

