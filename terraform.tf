terraform {
  backend "remote" {
    organization = "your-organization"

    workspaces {
      name = "tf-circleci-runners-example"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.10.0"
    }
  }
}
