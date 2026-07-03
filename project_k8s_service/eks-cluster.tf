module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.23.0"

  name               = "myapp-eks-cluster"
  kubernetes_version = "1.33"

  # Optional
  endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true


  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  tags = {
  environment = "development"
  application = "myapp"
  }

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    dev = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t2.small"]
      min_size     = 1
      max_size     = 3
      desired_size = 3
    }
  }
}