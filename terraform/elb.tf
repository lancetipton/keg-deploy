resource "aws_elb" "keg_elb" {
  name                      = "keg-deploy-elb"
  instances                 = [aws_instance.keg_app.id]
  subnets                   = [aws_subnet.keg_public_subnet.id, aws_subnet.keg_private_subnet.id]
  cross_zone_load_balancing = true

  tags = {
    "Name" = "Keg Deploy - ELB"
  }

  health_check {
    healthy_threshold   = 2
    interval            = 30
    target              = "HTTP:9999/"
    timeout             = 5
    unhealthy_threshold = 2
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "arn:aws:acm:us-west-2:559862229312:certificate/8a675018-22c6-4161-ac4c-804f4207c18d"
  }
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

