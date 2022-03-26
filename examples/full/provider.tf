terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.64.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}
