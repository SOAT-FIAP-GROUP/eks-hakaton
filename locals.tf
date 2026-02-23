data "aws_availability_zones" "available" {}

locals {
  region             = var.aws_region
  bucket             = var.bucket
  active_profile     = var.active_profile
  name               = "${var.local_name.name}-${var.local_name.env}"
  vpc_cidr           = var.vpc_cidr_block
  azs                = slice(data.aws_availability_zones.available.names, 0, var.vpc_subnets_count)
  kubernetes_version = "1.32"
  instance_types     = ["t3.small", "t3a.small"] #t3.micro don't work
  # instance_types     = ["t3.medium"]
  eks_nodes_ami_type = "AL2023_x86_64_STANDARD"
  container_port     = var.container_port
  docker_image       = var.docker_image
  tags = {
    Terraform = "true",
    Name      = var.local_name.name,
    Env       = var.local_name.env
  }
}