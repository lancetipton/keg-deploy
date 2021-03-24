
variable "keg_server_env" {
  default = "/keg/mounted/server.env"
}

variable "keg_server_provision" {
  default = "/keg/mounted/provision.sh"
}

variable "keg_ssh_key_public" {
  default = "/keg/mounted/ssh/keg-deploy-ssh.pub"
}

variable "keg_ec2_provision" {
  default = "/keg/terraform/provision.sh"
}

variable "keg_ssh_key_private" {
  default = "/keg/mounted/ssh/keg-deploy-ssh"
}

variable "aws_region" {
  default = "us-west-2"
}

variable "aws_ami" {
  description = "AWS AMI used to create the EC2 instance"
  default     = "ami-048c9d7c1a195950b"
}

variable "aws_instance_name" {
  description = "EC2 instance name"
  default     = "keg-deploy-app"
}

variable "aws_instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "aws_instance_user" {
  description = "EC2 instance user name"
  default     = "ubuntu"
}

variable "aws_vpc_cidr" {
  description = "CIDR for the VPC"
  default     = "10.0.0.0/16"
}

variable "aws_public_subnet_cidr" {
  description = "CIDR for the public subnet"
  default     = "10.0.10.0/24"
}

variable "aws_public_subnet_av_zone" {
  description = "Availability Zone for the public subnet"
  default     = "us-west-2a"
}

variable "aws_private_subnet_cidr" {
  description = "CIDR for the private subnet"
  default     = "10.0.20.0/24"
}

variable "aws_private_subnet_av_zone" {
  description = "Availability Zone for the private subnet"
  default     = "us-west-2b"
}

