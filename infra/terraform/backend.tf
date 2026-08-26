terraform {
  backend "s3" {
    bucket         = "togglemaster-tfstate-aae8e850"
    key            = "fase3/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile   = true
  }
}
