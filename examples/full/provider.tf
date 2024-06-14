terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}
