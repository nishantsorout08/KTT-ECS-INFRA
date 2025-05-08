terraform {
  backend "s3" {
    bucket         = "ktt-terraform-backup-bucket"
    key            = "terraform.tfstate"
    region         = "ap-south-1"
  }
}