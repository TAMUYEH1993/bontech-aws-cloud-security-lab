# Evidence 04 — Final Terraform Zero-Drift Check

## Objective

Confirm that the deployed AWS infrastructure matched the Terraform configuration after the final round of changes and validation.

## Final command

```bash
terraform plan
```

## Result

```text
No changes. Your infrastructure matches the configuration.
```

Terraform compared the declared configuration with the managed infrastructure and detected no pending changes at that point in the lab.

## Why this matters

This was the final technical checkpoint for Day 5. It showed that:

- the security changes had already been applied;
- Terraform state and configuration were aligned with the managed resources;
- there was no known configuration drift requiring another apply;
- the project ended with a verified state rather than an unreviewed deployment.

## Engineering takeaway

Infrastructure as Code is valuable not only for creating resources. It also provides a repeatable mechanism for reviewing change, detecting drift, and validating that the environment remains consistent with the intended configuration.

## Skills demonstrated

- Terraform plan analysis
- Configuration-drift checking
- Desired-state reasoning
- Post-change verification
- Infrastructure lifecycle management
