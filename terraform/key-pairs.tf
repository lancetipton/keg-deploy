resource "aws_key_pair" "keg_public_ssh" {
  key_name   = "keg-deploy"
  public_key = file(var.keg_ssh_key_public)
}

