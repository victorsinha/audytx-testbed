
provider "aws" {
  profile = var.profile
  region  = var.region
}

provider "aws" {
  alias      = "plain_text_access_keys_provider"
  region     = "us-west-1"
  access_key = "REDACTED-FOR-PUSH-PROTECTION"
  secret_key = "REDACTED-FOR-PUSH-PROTECTION"
}

terraform {
  backend "s3" {
    encrypt = true
  }
}
