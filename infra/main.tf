# Remote backend: state stored in S3, locked via DynamoDB.
# Run backend/ first to create these resources before initialising here.
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
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

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  my_ip = "${chomp(data.http.my_ip.response_body)}/32"
}

# ── Modules ───────────────────────────────────────────────────────────────────

module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  aws_region   = var.aws_region
  my_ip        = local.my_ip
}

module "compute" {
  source        = "./modules/compute"
  project_name  = var.project_name
  subnet_id     = module.networking.public_subnet_id
  sg_id         = module.networking.monitoring_sg_id
  instance_type = var.instance_type
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

resource "local_file" "ansible_inventory" {
  filename = "${path.root}/ansible/inventory.ini"
  content  = <<-EOT
    [monitoring]
    ${module.compute.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/monitoring ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_python_interpreter=/usr/bin/python3
  EOT
}
