# Evidence 03 — Terraform Infrastructure Validation

## Objective

Rebuild the cloud environment with Infrastructure as Code (IaC), apply security hardening through code, and verify the environment after change.

## Terraform-managed components

- VPC
- Public and private subnets
- Internet Gateway
- NAT Gateway and Elastic IP
- Public and private route tables
- Route-table associations
- Public and private Security Groups
- Public and private EC2 instances
- Apache bootstrap configuration
- Encrypted EBS root volumes

## Security hardening implemented as code

```hcl
root_block_device {
  encrypted   = true
  volume_type = "gp3"
  volume_size = 8
}
```

I also required IMDSv2 for the EC2 metadata service.

## Change impact

When root-volume encryption was added, Terraform identified that both EC2 instances required replacement rather than an in-place update.

The plan showed a destructive change, so I reviewed the plan before applying it. After replacement, I revalidated:

- public web access;
- SSH access to the public bastion;
- the second SSH hop to the private server;
- private outbound Internet connectivity through NAT;
- encrypted root storage;
- EC2 metadata protection.

## Important lesson

A successful `terraform apply` is not the end of a change. Infrastructure changes must be functionally retested because replacement can alter runtime properties such as public and private IP addresses.

## Skills demonstrated

- Terraform IaC
- Change-impact analysis
- Destructive plan review
- EC2 hardening
- EBS encryption
- IMDSv2
- Post-change verification
