module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "raheem-eks-cluster"
  cluster_version = "1.31"

  # ACCESS: Grants your 'devops-admin' user the keys to the cluster 
  enable_cluster_creator_admin_permissions = true

  # NETWORK: Connecting the Brain to the Land
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  # CONNECTIVITY: Mac-to-Cloud Bridge
  cluster_endpoint_public_access = true

  # STORAGE: The "Hands" that grab AWS hard drives for MySQL
  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # THE "MUSCLE": Worker nodes
  eks_managed_node_groups = {
    raheem_nodes = {
      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2 

      # PERMISSIONS: What the nodes are allowed to do
      iam_role_additional_policies = {
        AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
        AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        
        # REQUIRED FOR STORAGE: Permission to talk to AWS EBS
        AmazonEBSCSIDriverPolicy           = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }

  tags = {
    Environment = "production"
    GithubRepo  = "The-DevOps-Blueprint"
  }
}