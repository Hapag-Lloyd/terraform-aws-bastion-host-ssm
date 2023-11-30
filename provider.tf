terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}
