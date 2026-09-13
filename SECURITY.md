# Security Policy

## Purpose

This repository is a public technical portfolio for the BonTech AWS Cloud Security Engineering Lab. It is intentionally sanitized so that the project can demonstrate cloud-security engineering skills without exposing credentials, private keys, account-specific secrets, or sensitive operational data.

## Sensitive data that must never be committed

Do not commit any of the following:

- AWS access key IDs or secret access keys
- Session tokens or credentials files
- PEM, private SSH, P12/PFX, or other private key material
- Multi-Factor Authentication (MFA) QR codes, seeds, or recovery values
- Terraform state files (`*.tfstate`, `*.tfstate.*`)
- Real `terraform.tfvars` files containing local or sensitive values
- AWS account IDs when not needed for demonstration
- Full IAM, KMS, SNS, or resource ARNs when they expose account-specific identifiers
- SNS subscription or unsubscribe URLs
- CloudTrail request IDs, GuardDuty finding IDs, or other identifiers that are unnecessary for the public portfolio
- Screenshots containing secrets, credentials, personal data, or unredacted sensitive identifiers

## Terraform safety

The repository includes a `.gitignore` designed to block local Terraform state, private variable files, credentials, PEM keys, and other common sensitive artifacts.

Before committing Terraform changes:

```bash
terraform fmt
terraform validate
terraform plan
```

Review the plan before applying infrastructure changes.

Never store AWS credentials directly inside Terraform source files.

## Screenshot sanitization

Before adding screenshots to `evidence/`:

1. Crop to the relevant technical evidence.
2. Redact account IDs, access-key identifiers, MFA information, sensitive URLs, and unnecessary ARNs.
3. Verify browser tabs, address bars, notifications, and terminal history do not reveal secrets.
4. Prefer sanitized evidence over full-console screenshots.

## If a secret is exposed

If any credential or private key is accidentally published:

1. Treat the credential as compromised.
2. Revoke, delete, or rotate it immediately in the source system.
3. Remove it from the repository.
4. If necessary, rewrite repository history because deleting the latest file alone may not remove the value from earlier commits.
5. Review relevant AWS logs for unexpected use.

## Reporting a problem

If you discover sensitive information in this repository, do not repost the value in a public issue. Contact the repository owner privately so the material can be removed and any affected credential can be rotated.

## Portfolio principle

Public evidence should demonstrate the engineering decision, validation result, or investigation method—not expose the underlying secret.
