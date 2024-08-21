terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.63.1"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}
