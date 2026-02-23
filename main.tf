data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = local.bucket
    key    = "env:/${terraform.workspace}/network/terraform.tfstate"
    region = local.region
  }
}

data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket = local.bucket
    key    = "env:/${terraform.workspace}/rds/terraform.tfstate"
    region = local.region
  }
}

module "eks_outbound_to_rds" { #outbound MariaDB at ECS to RDS-sg
  source            = "terraform-aws-modules/security-group/aws"
  create_sg         = false
  security_group_id = data.terraform_remote_state.rds.outputs.sg_eks_id
  computed_egress_with_source_security_group_id = [
    {
      rule                     = "mysql-tcp"
      source_security_group_id = data.terraform_remote_state.rds.outputs.sg_rds_id
    }
  ]
  number_of_computed_egress_with_source_security_group_id = 1
  depends_on = [data.terraform_remote_state.rds]
}

module "rds_inbound_from_eks" { #inbound MariaDB at RDS from ECS-sg
  source            = "terraform-aws-modules/security-group/aws"
  create_sg         = false
  security_group_id = data.terraform_remote_state.rds.outputs.sg_rds_id
  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "mysql-tcp"
      source_security_group_id = data.terraform_remote_state.rds.outputs.sg_eks_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1
  depends_on = [data.terraform_remote_state.rds]
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  putin_khuylo    = true
  cluster_name    = local.name
  cluster_version = local.kubernetes_version

  # EKS Addons
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id     = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnets

  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_private_access          = false
  cluster_endpoint_public_access           = true
  cluster_endpoint_public_access_cidrs     = ["0.0.0.0/0"]

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    # instance_types = ["t3.micro", "m6i.large", "m5.large", "m5n.large", "m5zn.large"]
    instance_types = local.instance_types
  }

  eks_managed_node_groups = {
    (local.name) = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type = local.eks_nodes_ami_type

      min_size               = 2
      max_size               = 3
      desired_size           = 2
      capacity_type          = "ON_DEMAND"
      vpc_security_group_ids = [data.terraform_remote_state.rds.outputs.sg_eks_id]
      launch_template_name = "${local.name}-eks-mng-nodes-template"
      labels               = local.tags
    }
  }

  node_security_group_name            = "${local.name}-node-sg"
  node_security_group_tags            = local.tags
  node_security_group_use_name_prefix = true # node security group name (node_security_group_name) is used as a prefix

  enable_irsa                      = false
  create_kms_key                   = false
  attach_cluster_encryption_policy = false
  cluster_encryption_config        = []

  tags = local.tags
}