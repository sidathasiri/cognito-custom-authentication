provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "lambda_exec" {
  name = "cognito_custom_auth_lambda_exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "cognito-idp.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "sns_publish_policy" {
  name        = "sns-publish"
  description = "Allow publishing SMS messages"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sns:Publish",
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sns_publish" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.sns_publish_policy.arn
}

data "archive_file" "define_auth_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/define-auth-challenge.js"
  output_path = "${path.module}/lambda/define-auth-challenge.zip"
}

data "archive_file" "create_auth_zip" {
  type        = "zip"
  source_dir = "${path.module}/lambda/create-auth-challenge"
  output_path = "${path.module}/lambda/create-auth-challenge.zip"
}

data "archive_file" "verify_auth_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/verify-auth-challenge.js"
  output_path = "${path.module}/lambda/verify-auth-challenge.zip"
}

resource "aws_lambda_function" "define_auth" {
  function_name = "DefineAuthChallenge"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "define-auth-challenge.handler"
  runtime       = "nodejs22.x"
  filename      = data.archive_file.define_auth_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.define_auth_zip.output_path)
}

resource "aws_lambda_function" "create_auth" {
  function_name = "CreateAuthChallenge"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "create-auth-challenge.handler"
  runtime       = "nodejs22.x"
  filename      = data.archive_file.create_auth_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.create_auth_zip.output_path)
}

resource "aws_lambda_function" "verify_auth" {
  function_name = "VerifyAuthChallenge"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "verify-auth-challenge.handler"
  runtime       = "nodejs22.x"
  filename      = data.archive_file.verify_auth_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.verify_auth_zip.output_path)
}

resource "aws_cognito_user_pool" "custom_auth_pool" {
  name = "custom-auth-user-pool"

  lambda_config {
    define_auth_challenge        = aws_lambda_function.define_auth.arn
    create_auth_challenge        = aws_lambda_function.create_auth.arn
    verify_auth_challenge_response = aws_lambda_function.verify_auth.arn
  }

  sms_configuration {
    external_id    = "cognito-sms-external-id"
    sns_caller_arn = aws_iam_role.lambda_exec.arn
  }

  sms_authentication_message = "Your authentication code is {####}"

  auto_verified_attributes = ["phone_number"]

  schema {
    name     = "phone_number"
    attribute_data_type      = "String"
    required = true
    mutable  = true
  }

  username_attributes = ["phone_number"]
}

resource "aws_cognito_user_pool_client" "app_client" {
  name         = "custom-auth-app-client"
  user_pool_id = aws_cognito_user_pool.custom_auth_pool.id
  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

# Permissions for Cognito to invoke Lambda
resource "aws_lambda_permission" "define_auth" {
  statement_id  = "AllowCognitoInvokeDefineAuth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.define_auth.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.custom_auth_pool.arn
}

resource "aws_lambda_permission" "create_auth" {
  statement_id  = "AllowCognitoInvokeCreateAuth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_auth.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.custom_auth_pool.arn
}

resource "aws_lambda_permission" "verify_auth" {
  statement_id  = "AllowCognitoInvokeVerifyAuth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.verify_auth.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.custom_auth_pool.arn
}
