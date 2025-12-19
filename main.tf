# Main Terraform configuration for ECS infrastructure
# Following AWS Well-Architected Framework and CIS v4 controls

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Enable state encryption (CIS 2.8)
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "ecs/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment   = var.environment
      Project       = var.project_name
      ManagedBy     = "Terraform"
      Owner         = var.owner
      CostCenter    = var.cost_center
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  environment         = var.environment
  project_name        = var.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = data.aws_availability_zones.available.names
  
  tags = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security"
  
  vpc_id       = module.vpc.vpc_id
  environment  = var.environment
  project_name = var.project_name
  
  tags = local.common_tags
}

# IAM Module
module "iam" {
  source = "./modules/iam"
  
  environment  = var.environment
  project_name = var.project_name
  account_id   = data.aws_caller_identity.current.account_id
  
  tags = local.common_tags
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"
  
  environment  = var.environment
  project_name = var.project_name
  
  tags = local.common_tags
}

# ALB Module
module "alb" {
  source = "./modules/alb"
  
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  security_group_ids  = [module.security_groups.alb_security_group_id]
  environment         = var.environment
  project_name        = var.project_name
  
  tags = local.common_tags
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"
  
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  security_group_ids        = [module.security_groups.ecs_security_group_id]
  target_group_arn          = module.alb.target_group_arn
  task_execution_role_arn   = module.iam.ecs_task_execution_role_arn
  task_role_arn            = module.iam.ecs_task_role_arn
  ecr_repository_url       = module.ecr.repository_url
  environment              = var.environment
  project_name             = var.project_name
  
  # Right-sizing configuration
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  desired_count           = var.ecs_desired_count
  min_capacity            = var.ecs_min_capacity
  max_capacity            = var.ecs_max_capacity
  
  # KMS encryption keys
  secrets_kms_key_id       = module.iam.secrets_kms_key_id
  logs_kms_key_arn         = module.iam.logs_kms_key_arn
  
  tags = local.common_tags
}

# Locals for common tags
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
  }
}