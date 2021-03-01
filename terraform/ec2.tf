resource "aws_instance" "keg_app" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  key_name      = aws_key_pair.keg_public_ssh.key_name

  subnet_id              = aws_subnet.keg_public_subnet.id
  vpc_security_group_ids = [aws_security_group.keg_sg_public.id]

  source_dest_check           = false
  associate_public_ip_address = true

  provisioner "file" {
    source      = var.keg_server_env
    destination = "/home/${var.aws_instance_user}/server.env"
  }

  provisioner "file" {
    source      = var.keg_sever_provision
    destination = "/home/${var.aws_instance_user}/mounted-provision.sh"
  }

  provisioner "file" {
    source      = var.keg_ec2_provision
    destination = "/home/${var.aws_instance_user}/provision.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash /home/${var.aws_instance_user}/provision.sh",
      "bash /home/${var.aws_instance_user}/mounted-provision.sh",
    ]
  }

  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = var.aws_instance_user
    private_key = file(var.keg_ssh_key_private)
  }

  tags = {
    Name = "Keg Deploy - EC2 Instance"
  }
}

