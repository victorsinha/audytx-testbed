environment = "prod"
project     = "example"
region      = "us-east-1"

env_config = {
  dev = {
    instance_type  = "t3.micro"
    instance_count = 1
  }
  staging = {
    instance_type  = "t3.small"
    instance_count = 2
  }
  prod = {
    instance_type  = "m5.large"
    instance_count = 4
  }
}
