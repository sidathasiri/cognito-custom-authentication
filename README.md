# Cognito Custom Authentication with Lambda and Terraform

This project demonstrates how to implement a custom authentication flow for Amazon Cognito using AWS Lambda functions, managed and deployed with Terraform.

## Features
- **Custom Cognito User Pool** with phone number as the username.
- **Custom authentication flow** using Lambda triggers:
  - `DefineAuthChallenge`
  - `CreateAuthChallenge` (sends OTP via SMS)
  - `VerifyAuthChallengeResponse`
- **SMS-based OTP delivery** using AWS SNS.
- **Terraform** for infrastructure as code, including IAM roles, policies, Lambda packaging, and Cognito resources.

## Project Structure
```
main.tf                # Terraform configuration for AWS resources
variables.tf           # Terraform variables
outputs.tf             # Terraform outputs
terraform.tfstate      # Terraform state (should be gitignored)
lambda/
  create-auth-challenge.js         # Lambda handler for CreateAuthChallenge
  define-auth-challenge.js         # Lambda handler for DefineAuthChallenge
  verify-auth-challenge.js         # Lambda handler for VerifyAuthChallenge
  create-auth-challenge.zip        # Zipped Lambda package (gitignored)
  define-auth-challenge.zip        # Zipped Lambda package (gitignored)
  verify-auth-challenge.zip        # Zipped Lambda package (gitignored)
  create-auth-challenge/
    package.json                   # Node.js dependencies for CreateAuthChallenge
    README.md                      # Function-specific documentation
    node_modules/                  # Node.js dependencies (gitignored)
```

## Getting Started

### Prerequisites
- AWS CLI configured
- Terraform installed
- Node.js (for Lambda packaging)

### Setup & Deployment
1. **Install dependencies for Lambda functions** (if needed):
   ```sh
   cd lambda/create-auth-challenge
   npm install
   cd ../..
   # Repeat for other Lambda functions if they have dependencies
   ```
2. **Initialize and apply Terraform:**
   ```sh
   terraform init
   terraform apply
   ```
3. **Cognito User Pool and Lambdas** will be created. The custom authentication flow will use SMS OTPs.

### Packaging Lambda Functions
- Lambda zips are created automatically by Terraform using the `archive_file` data source.
- Only include your handler and required dependencies (do not include `aws-sdk`).

## Setting Up a Test User

1. **Create a user:**
   ```sh
   aws cognito-idp admin-create-user \
     --user-pool-id <USER_POOL_ID> \
     --username "<PHONE_NUMBER>" \
     --user-attributes Name=phone_number,Value="<PHONE_NUMBER>" Name=phone_number_verified,Value=true \
     --message-action SUPPRESS
   ```
2. **Confirm user by setting a password:**
   ```sh
   aws cognito-idp admin-set-user-password \
     --user-pool-id <USER_POOL_ID> \
     --username "<PHONE_NUMBER>" \
     --password 'your_password' \
     --permanent
   ```
3. **If you use SNS sandbox mode, register and verify this number first.**

## Security & Best Practices
- Do not commit secrets or AWS credentials.
- `.gitignore` excludes sensitive and build files.
- Use environment variables for sensitive configuration if needed.