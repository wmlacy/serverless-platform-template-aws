# Cognito JWT Auth

Cognito is off by default. This doc covers how to enable it, what Terraform
creates, and how to get a token and call a protected endpoint.

## Enable

Add to `infra/envs/dev/dev.auto.tfvars`:

```hcl
enable_cognito = true
```

Then deploy:

```bash
cd infra/envs/dev
terraform plan -out=tfplan
terraform apply tfplan
```

## Terraform outputs

After apply, note these values:

```bash
terraform output cognito_user_pool_id   # e.g. us-east-1_AbCdEfGhI
terraform output cognito_client_id      # e.g. 1a2b3c4d5e6f7g8h9i0j
```

## Create a test user

```bash
aws cognito-idp sign-up \
  --client-id <client_id> \
  --username testuser \
  --password "TestPass1!" \
  --region us-east-1

aws cognito-idp admin-confirm-sign-up \
  --user-pool-id <user_pool_id> \
  --username testuser \
  --region us-east-1
```

## Get a token

```bash
TOKEN=$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id <client_id> \
  --auth-parameters USERNAME=testuser,PASSWORD="TestPass1!" \
  --region us-east-1 \
  --query "AuthenticationResult.IdToken" \
  --output text)
```

## Call a protected endpoint

```bash
API_URL=$(terraform -chdir=infra/envs/dev output -raw api_base_url)

# Public — no token needed
curl -s "${API_URL}/health" | jq .

# Protected — requires token
curl -s -X POST "${API_URL}/items" \
  -H "Authorization: ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"id":"cog-test","name":"cognito item"}' | jq .

curl -s "${API_URL}/items/cog-test" \
  -H "Authorization: ${TOKEN}" | jq .
```

## Disable

Remove `enable_cognito = true` from `dev.auto.tfvars` (or set it to `false`),
then re-plan and apply. All routes revert to public `NONE` auth.
