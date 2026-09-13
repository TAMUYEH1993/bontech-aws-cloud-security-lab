# BonTech AWS Cloud Security Engineering Lab

![Architecture](assets/architecture.png)

## Overview

This repository documents an end-to-end **Amazon Web Services (AWS) cloud security engineering lab** that I designed, built, secured, monitored, investigated, and automated.

The project began with manual network design and implementation so I could understand how the components interact. I then added security visibility, detection, identity hardening, and investigation workflows. Finally, I rebuilt the environment with **Terraform Infrastructure as Code (IaC)** and validated the deployment after security changes.

The purpose of this repository is to demonstrate practical skills in:

- AWS networking and cloud architecture
- Linux systems administration
- Identity and access management
- Security monitoring and detection engineering
- Security Operations Center (SOC) investigation workflows
- Terraform Infrastructure as Code
- Troubleshooting and post-change validation

> **Security note:** All public material in this repository is sanitized. Credentials, private keys, AWS account identifiers, access-key identifiers, Multi-Factor Authentication (MFA) secrets, unsubscribe links, and other sensitive values are intentionally excluded.

---

## Project Architecture

The environment uses a segmented **Virtual Private Cloud (VPC)** with separate public and private subnets.

```text
                         Internet
                            |
                     Internet Gateway
                            |
              +-------------+-------------+
              |                           |
      Public Route Table            NAT Gateway
        0.0.0.0/0 -> IGW            + Elastic IP
              |                           ^
       Public Subnet                      |
              |                    Private Route Table
      Public EC2 Server             0.0.0.0/0 -> NAT
       Web + Bastion                       ^
              |                            |
              +------ SSH ----------> Private Subnet
                                           |
                                   Private EC2 Server
                                   No Public IPv4
```

Security visibility was layered on top of the network:

```text
CloudTrail -------------------------> API audit evidence
VPC Flow Logs -> CloudWatch Logs ---> Network-flow evidence
                     |
                     +-> Metric Filter
                          |
                          +-> CloudWatch Alarm
                                |
                                +-> Amazon SNS -> Email alert

GuardDuty --------------------------> Threat-detection findings
IAM + MFA --------------------------> Administrative identity hardening
Terraform --------------------------> Repeatable infrastructure + drift checks
```

---

## Project Progression

### Day 1 - Architecture and Networking Fundamentals

I designed the network before deploying resources. The original manual environment used:

- VPC: `10.0.0.0/16`
- Public subnet: `10.0.1.0/24`
- Private subnet: `10.0.2.0/24`
- Public default route: `0.0.0.0/0 -> Internet Gateway`
- Private default route: `0.0.0.0/0 -> NAT Gateway`

Key concepts demonstrated:

- Classless Inter-Domain Routing (CIDR)
- Public versus private subnet behavior
- Route-table decision making
- Security Groups versus Network Access Control Lists (NACLs)
- RFC 1918 private addressing
- Difference between routing and filtering

### Day 2 - Deployment, Bastion Access, and NAT Validation

I manually deployed the AWS environment and validated each traffic path.

I built:

- VPC and public/private subnets
- Internet Gateway
- Public and private route tables
- NAT Gateway
- Public Amazon Elastic Compute Cloud (EC2) web/bastion server
- Private EC2 server with no public IPv4 address
- Security Groups controlling inbound administrative access

I used **Secure Shell (SSH) agent forwarding** so I could connect to the private server through the public bastion without copying the private key onto the bastion host.

Validation included:

```bash
ssh-add "$HOME/Desktop/<key-file>.pem"
ssh -A ec2-user@<public-ip>
ssh ec2-user@<private-ip>
```

From the private server, I verified outbound Internet access through the NAT Gateway:

```bash
curl https://checkip.amazonaws.com
curl -I https://www.google.com
```

This proved that the private server could initiate outbound connections while remaining directly unreachable from the public Internet.

### Day 3 - Logging and Detection Engineering

I enabled security visibility using:

- AWS CloudTrail
- VPC Flow Logs
- Amazon CloudWatch Logs
- CloudWatch Logs Insights
- CloudWatch custom metric filter
- CloudWatch alarm
- Amazon Simple Notification Service (SNS)

Detection pipeline:

```text
VPC Flow Logs
    -> CloudWatch Logs
        -> Metric Filter
            -> RejectedTrafficCount
                -> CloudWatch Alarm
                    -> Amazon SNS
                        -> Email notification
```

I validated CloudTrail using real account activity and validated the alert pipeline by receiving an actual alarm notification.

### Day 4 - GuardDuty, IAM Hardening, and SOC Investigation

I enabled Amazon GuardDuty and used sample findings to practice investigation workflows.

I also hardened administrative identity usage by:

- Keeping Multi-Factor Authentication (MFA) enabled for the root account
- Confirming the root account had no active access keys
- Creating a dedicated IAM administrator
- Enabling MFA for the IAM administrator
- Moving routine administrative work away from the root user

Using CloudWatch Logs Insights, I investigated rejected SSH traffic and compared `ACCEPT` and `REJECT` VPC Flow Log records.

A major analytical lesson from the investigation was:

> A VPC Flow Log `ACCEPT` record means the network layer allowed a flow. It does **not** prove that SSH authentication succeeded or that a host was compromised.

Host authentication logs must be correlated before making that conclusion.

### Day 5 - Terraform Infrastructure as Code

After understanding the architecture manually, I rebuilt it with Terraform.

The Terraform environment uses:

- VPC: `10.10.0.0/16`
- Public subnet: `10.10.1.0/24`
- Private subnet: `10.10.2.0/24`

Terraform manages:

- VPC
- Public/private subnets
- Internet Gateway
- NAT Gateway and Elastic IP
- Route tables and associations
- Security Groups
- Public and private EC2 instances
- Apache bootstrap configuration
- Encrypted root Elastic Block Store (EBS) volumes

I hardened both EC2 root volumes with encryption:

```hcl
root_block_device {
  encrypted   = true
  volume_type = "gp3"
  volume_size = 8
}
```

Terraform identified that the root-volume change required replacement of both EC2 instances. I reviewed the destructive plan before applying it and then revalidated the environment.

The final drift check returned:

```text
No changes. Your infrastructure matches the configuration.
```

That confirmed that the deployed infrastructure matched the Terraform configuration at the time of validation.

---

## Technical Reasoning Demonstrated

This project was intentionally built to show more than AWS console familiarity.

### Network reasoning

I can explain why:

- a subnet is public or private based on routing rather than its name;
- an Internet Gateway and NAT Gateway solve different connectivity problems;
- a private server does not need a public IPv4 address to reach package repositories;
- a Security Group reference can be safer than opening SSH to the Internet.

### Security reasoning

I can distinguish:

- routing from filtering;
- a network `ACCEPT` event from a successful user authentication;
- identity hardening from network hardening;
- alert generation from incident confirmation.

### Infrastructure reasoning

I used Terraform to understand:

- desired state versus deployed state;
- resource replacement versus in-place updates;
- destructive plan review;
- configuration drift;
- post-change validation.

---

## Repository Structure

```text
bontech-aws-cloud-security-lab/
|
|-- README.md
|-- SECURITY.md
|-- .gitignore
|
|-- assets/
|   `-- architecture.png
|
|-- terraform/
|   |-- versions.tf
|   |-- variables.tf
|   |-- main.tf
|   |-- outputs.tf
|   `-- terraform.tfvars.example
|
|-- queries/
|   `-- cloudwatch-logs-insights.md
|
|-- docs/
|   |-- project-timeline.md
|   `-- lessons-learned.md
|
`-- evidence/
    `-- README.md
```

---

## Terraform Quick Start

> This repository does not contain AWS credentials or Terraform state files.

1. Install Terraform and configure AWS authentication outside the repository.
2. Copy the example variables file:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

3. Edit the local `terraform.tfvars` values.
4. Initialize and validate:

```bash
cd terraform
terraform init
terraform fmt -check
terraform validate
terraform plan
```

5. Review the plan carefully before applying:

```bash
terraform apply
```

---

## Selected Security Controls

| Control | Implementation |
|---|---|
| Network segmentation | Separate public and private subnets |
| Private workload isolation | Private EC2 has no public IPv4 |
| Administrative access | SSH restricted to a trusted source and bastion path |
| Private outbound connectivity | NAT Gateway |
| Storage protection | Encrypted EBS root volumes |
| Metadata protection | IMDSv2 required |
| Audit logging | AWS CloudTrail |
| Network telemetry | VPC Flow Logs |
| Detection | CloudWatch metric filter + alarm |
| Notification | Amazon SNS |
| Threat detection | Amazon GuardDuty |
| Identity hardening | IAM administrator + MFA; routine root usage eliminated |
| Infrastructure automation | Terraform IaC |
| Drift validation | Final `terraform plan` with no changes |

---

## Investigation Queries

Reusable CloudWatch Logs Insights examples are stored in:

[`queries/cloudwatch-logs-insights.md`](queries/cloudwatch-logs-insights.md)

They demonstrate:

- rejected traffic review;
- top rejected source addresses;
- SSH destination-port analysis;
- source-specific `ACCEPT` versus `REJECT` correlation.

---

## Lessons Learned

The most important lesson from this project is that cloud security engineering requires **validation**, not assumptions.

A resource being present in the AWS console does not prove the architecture is correct. I validated the design with actual web requests, SSH sessions, NAT egress tests, audit records, network-flow queries, alert notifications, Terraform state inspection, and a final zero-drift plan.

See [`docs/lessons-learned.md`](docs/lessons-learned.md) for the detailed troubleshooting record.

---

## Future Improvements

Possible extensions include:

- AWS IAM Identity Center and temporary credentials
- Stricter least-privilege IAM roles
- AWS Config and Security Hub
- Automated remediation using Lambda
- Continuous Integration / Continuous Delivery (CI/CD) validation for Terraform
- Terraform modules and remote state
- Additional host-level telemetry and detection correlation
- Multi-Availability-Zone architecture

---

## Author

**Bonaventure Tamuyeh**  
Cybersecurity / SOC Analyst | Cloud Security Engineering Portfolio

This project was built as an independent technical lab to strengthen cloud security engineering, infrastructure automation, systems troubleshooting, and security investigation skills.
