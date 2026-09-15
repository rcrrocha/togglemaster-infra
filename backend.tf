terraform {
  backend "s3" {
  bucket = "fiap-tfstate-rocha-574349219641"
  key = "prod/terraform.tfstate"
  region = "us-east-1"
  encrypt = true
  use_lockfile = true
  }
}
