# User authentication for the mobile app.
resource "aws_cognito_user_pool" "main" {
  name = "${local.name_prefix}-users"

  # Email-based sign-in/recovery.
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 12
    require_uppercase                = true
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 3
  }

  # Require MFA; mobile clients use TOTP.
  mfa_configuration = "ON"
  software_token_mfa_configuration {
    enabled = true
  }

  # Protect against credential-stuffing / takeover.
  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  deletion_protection = "ACTIVE"
}

# Public mobile client. No generated secret: native/mobile apps cannot
# keep a client secret confidential, so we omit it and rely on PKCE.
resource "aws_cognito_user_pool_client" "mobile" {
  name         = "${local.name_prefix}-mobile-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  # Short-lived access tokens, longer refresh window for app sessions.
  access_token_validity  = 1
  id_token_validity       = 1
  refresh_token_validity = 30
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true
}
