module "vpc" {
  source = "./modules/vpc"

  vpc_cidr                   = var.vpc_cidr
  availability_zones         = var.availability_zones
  public_subnet_cidrs        = var.public_subnet_cidrs
  private_app_subnet_cidrs   = var.private_app_subnet_cidrs
  private_db_subnet_cidrs    = var.private_db_subnet_cidrs
  project_name               = var.project_name
  environment                = var.environment
}

module "security" {
  source = "./modules/security"

  vpc_id           = module.vpc.vpc_id
  project_name     = var.project_name
  environment      = var.environment
}

module "compute" {
  source = "./modules/compute"

  vpc_id                      = module.vpc.vpc_id
  public_subnet_ids           = module.vpc.public_subnet_ids
  private_app_subnet_ids      = module.vpc.private_app_subnet_ids
  alb_security_group_id       = module.security.alb_security_group_id
  ec2_security_group_id       = module.security.ec2_security_group_id
  instance_type               = var.instance_type
  asg_min_size                = var.asg_min_size
  asg_max_size                = var.asg_max_size
  asg_desired_capacity        = var.asg_desired_capacity
  project_name                = var.project_name
  environment                 = var.environment
  enable_detailed_monitoring  = var.enable_detailed_monitoring
}

module "database" {
  source = "./modules/database"

  vpc_id                      = module.vpc.vpc_id
  private_db_subnet_ids       = module.vpc.private_db_subnet_ids
  db_security_group_id        = module.security.db_security_group_id
  db_instance_class           = var.db_instance_class
  db_engine                   = var.db_engine
  db_engine_version           = var.db_engine_version
  db_allocated_storage        = var.db_allocated_storage
  db_name                     = var.db_name
  db_username                 = var.db_username
  db_password                 = var.db_password
  project_name                = var.project_name
  environment                 = var.environment
  enable_detailed_monitoring  = var.enable_detailed_monitoring
}
