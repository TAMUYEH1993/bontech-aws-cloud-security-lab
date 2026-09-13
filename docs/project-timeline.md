# BonTech AWS Cloud Security Lab — Project Timeline

This document summarizes the progression of the project from foundational network design through monitoring, investigation, security hardening, and Infrastructure as Code.

## Day 1 — Network Architecture and AWS Foundations

Designed the AWS network before deployment.

Key work:

- Created a Virtual Private Cloud (VPC) using `10.0.0.0/16`.
- Designed a public subnet using `10.0.1.0/24`.
- Designed a private subnet using `10.0.2.0/24`.
- Connected an Internet Gateway to the VPC.
- Created separate public and private route tables.
- Routed public Internet traffic through the Internet Gateway.
- Routed private outbound traffic through a Network Address Translation (NAT) Gateway.
- Reviewed Security Groups and Network Access Control Lists (NACLs).

Primary learning objective: understand how routing, subnetting, gateways, and filtering combine to create a segmented cloud network.

## Day 2 — EC2 Deployment, Bastion Access, and Connectivity Validation

Deployed compute resources and validated the network design.

Key work:

- Deployed a public Amazon Elastic Compute Cloud (EC2) instance.
- Installed and tested an Apache web server.
- Deployed a private EC2 instance without a public IPv4 address.
- Restricted Secure Shell (SSH) access using Security Groups.
- Used the public EC2 instance as a bastion host.
- Used SSH agent forwarding instead of copying the private key to the bastion.
- Verified private outbound Internet access through the NAT Gateway.

Validation included:

```bash
ssh -A ec2-user@<public-ip>
ssh ec2-user@<private-ip>
curl https://checkip.amazonaws.com
curl -I https://www.google.com
```

Primary learning objective: prove that the public and private traffic paths behave as designed.

## Day 3 — Logging, Visibility, and Alerting

Added security telemetry and detection capabilities.

Key work:

- Enabled AWS CloudTrail for management-plane activity.
- Enabled VPC Flow Logs for network-flow visibility.
- Sent flow logs to Amazon CloudWatch Logs.
- Used CloudWatch Logs Insights for analysis.
- Created a metric filter for rejected traffic.
- Created a custom CloudWatch metric.
- Created a CloudWatch alarm for excessive rejected connections.
- Connected the alarm to Amazon Simple Notification Service (SNS).
- Confirmed receipt of a real alarm email.

Primary learning objective: turn raw cloud telemetry into actionable security detection.

## Day 4 — GuardDuty, IAM Hardening, and SOC Investigation

Expanded the project from monitoring into investigation and identity security.

Key work:

- Enabled Amazon GuardDuty.
- Generated and reviewed sample findings.
- Investigated root-credential-usage findings.
- Confirmed Multi-Factor Authentication (MFA) for the root account.
- Confirmed no active root access keys.
- Created a dedicated Identity and Access Management (IAM) administrator.
- Enabled MFA for the administrator.
- Moved routine administration away from the root account.
- Investigated rejected Secure Shell (SSH) traffic with CloudWatch Logs Insights.
- Compared `ACCEPT` and `REJECT` flow records.

Important analytical conclusion:

> A VPC Flow Log `ACCEPT` record confirms network-layer permission, not successful user authentication or system compromise.

Primary learning objective: correlate cloud security evidence before making an incident determination.

## Day 5 — Terraform Infrastructure as Code and Security Hardening

Rebuilt the architecture with Terraform and implemented security changes declaratively.

Terraform environment:

- VPC: `10.10.0.0/16`
- Public subnet: `10.10.1.0/24`
- Private subnet: `10.10.2.0/24`

Terraform managed:

- VPC
- Subnets
- Internet Gateway
- NAT Gateway
- Elastic IP
- Route tables and associations
- Security Groups
- Public and private EC2 instances
- Apache bootstrap configuration
- Encrypted Amazon Elastic Block Store (EBS) root volumes

Security-hardening change:

```hcl
root_block_device {
  encrypted   = true
  volume_type = "gp3"
  volume_size = 8
}
```

Terraform identified that changing the root-volume encryption configuration required EC2 replacement. The destructive plan was reviewed before applying the change.

Post-change validation included:

- public web service test;
- SSH to the public bastion;
- SSH from the bastion to the private server;
- private outbound connectivity through NAT;
- Terraform state inspection;
- verification of encrypted EBS volumes;
- verification that Instance Metadata Service Version 2 (IMDSv2) was required.

Final drift check:

```text
No changes. Your infrastructure matches the configuration.
```

Primary learning objective: manage secure infrastructure as code, understand replacement behavior, and validate the system after change.

## End-to-End Progression

```text
Architecture
   -> Manual Deployment
      -> Secure Access
         -> Logging
            -> Detection
               -> Investigation
                  -> IAM Hardening
                     -> Terraform IaC
                        -> Security Change
                           -> Post-Change Validation
                              -> Zero-Drift Check
```

The project is intentionally structured as one continuous engineering exercise rather than a collection of unrelated AWS demonstrations.
