environment = "dev"
project     = "example"
region      = "us-east-1"

# Override the defaults from variables.tf if you want different sizing for dev.
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
