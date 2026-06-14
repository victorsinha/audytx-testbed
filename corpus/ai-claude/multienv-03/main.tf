data "aws_ami" "al2023" {
  count       = var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  resolved_ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.al2023[0].id
}

resource "aws_instance" "app" {
  count = local.config.instance_count

  ami           = local.resolved_ami_id
  instance_type = local.config.instance_type

  # Enforce IMDSv2 (token required) to block SSRF-based credential theft.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Encrypt the root volume at rest.
  root_block_device {
    encrypted = true
  }

  # Do not auto-assign a public IP; place instances in private subnets.
  associate_public_ip_address = false

  # Drop EC2 instance metadata/console access defaults that leak info.
  monitoring = true

  tags = {
    Name = "${local.name_prefix}-app-${count.index + 1}"
  }
}
