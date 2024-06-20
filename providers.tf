locals {
  region = "us-east-1"
}
terraform {
  required_version = "~> 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = " ~> 4.0"
    }
  }
  cloud {
    organization = "AmitsMizs"

    workspaces {
      name = "main"
    }
  }
}

provider "aws" {
  region = local.region
}
