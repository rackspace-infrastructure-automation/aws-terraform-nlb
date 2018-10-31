provider "aws" {
  version = "~> 1.2, < 1.41.0"
  region  = "us-east-1"
}

resource "random_string" "r_string" {
  length  = 6
  lower   = true
  upper   = false
  number  = false
  special = false
}
