output "user_pool_id" {
  value = aws_cognito_user_pool.custom_auth_pool.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.app_client.id
}
