terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Intent: Use the stable version 5.x
    }
  }
}

provider "aws" {
  region = var.region # Intent: Don't hardcode; use a variable
}