# Remote backend: state stored in S3, locked via DynamoDB.
# Run backend/ first to create these resources before initialising here.
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "cedrick-monitoring-lab-state"
    key            = "monitoring-lab/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "monitoring-lab-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# ── Modules ───────────────────────────────────────────────────────────────────

module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  aws_region   = var.aws_region
  my_ip        = var.my_ip
}

module "compute" {
  source          = "./modules/compute"
  project_name    = var.project_name
  subnet_id       = module.networking.public_subnet_id
  sg_id           = module.networking.monitoring_sg_id
  instance_type   = var.instance_type
  public_key_path = var.public_key_path
}

module "cloudwatch" {
  source       = "./modules/cloudwatch"
  project_name = var.project_name
  instance_id  = module.compute.instance_id
}

module "cloudtrail" {
  source       = "./modules/cloudtrail"
  project_name = var.project_name
  aws_region   = var.aws_region
  environment  = var.environment
}

module "guardduty" {
  source       = "./modules/guardduty"
  project_name = var.project_name
  environment  = var.environment
}
