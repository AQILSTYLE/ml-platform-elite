module "vpc" {
  source = "../../modules/vpc"
}

module "eks" {
  source             = "../../modules/eks"
  cluster_name       = "ml-platform"
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
}
