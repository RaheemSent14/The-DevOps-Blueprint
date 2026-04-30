module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "raheem-devops-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  # CRITICAL FIX: Ensure instances get a public IP to talk to the EKS Brain
  map_public_ip_on_launch = true 

  # COST SAVING: Keep NAT Gateways disabled
  enable_nat_gateway = false 
  single_nat_gateway = false

  tags = {
    "Name"                                      = "raheem-vpc"
    "kubernetes.io/cluster/raheem-eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/raheem-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}