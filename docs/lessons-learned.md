# Lessons Learned and Troubleshooting Notes

This project was designed to capture not only successful deployment steps, but also the mistakes, troubleshooting process, and security reasoning that occurred along the way.

## 1. Build the Network Before the Applications

The project reinforced that a secure cloud deployment starts with network design.

Before launching workloads, I needed to understand:

- VPC address space;
- public and private subnets;
- route tables;
- Internet Gateway behavior;
- NAT Gateway behavior;
- Security Groups;
- Network Access Control Lists (NACLs).

This made later troubleshooting easier because I could reason about the expected path of traffic.

## 2. A Private Subnet Is Defined by Routing

One of the most important networking lessons was that the word `private` in a subnet name does not make the subnet private.

A private subnet is private because it does not have a direct default route to an Internet Gateway.

In this lab:

```text
Public subnet  -> 0.0.0.0/0 -> Internet Gateway
Private subnet -> 0.0.0.0/0 -> NAT Gateway
```

This distinction helped separate **routing decisions** from **firewall/filtering decisions**.

## 3. NAT Gateway Provides Outbound Connectivity, Not Public Reachability

The private EC2 instance needed Internet access for package installation and HTTPS requests, but it did not need to accept unsolicited inbound Internet connections.

The NAT Gateway allowed the private instance to initiate outbound connections while keeping the workload without a public IPv4 address.

A useful validation command was:

```bash
curl https://checkip.amazonaws.com
```

The returned public address represented the NAT Gateway's external address, not a public address assigned to the private EC2 instance.

## 4. Do Not Copy Private SSH Keys to Bastion Hosts

A safer bastion workflow used SSH agent forwarding.

From the local workstation:

```bash
ssh-add "$HOME/Desktop/<key-file>.pem"
ssh -A ec2-user@<public-ip>
```

Then from the bastion:

```bash
ssh ec2-user@<private-ip>
```

This allowed the private key to remain on the local workstation rather than being copied to the public server.

## 5. Connectivity Problems Require Layer-by-Layer Troubleshooting

SSH timeouts initially appeared to be a server problem, but troubleshooting required checking multiple layers:

- local Internet connectivity;
- current public source IP;
- Security Group rules;
- route tables;
- public IPv4 assignment;
- SSH key and username;
- instance state;
- network path.

This reinforced a systematic approach rather than changing random settings until something worked.

## 6. CloudTrail and VPC Flow Logs Answer Different Questions

CloudTrail records AWS API and management-plane activity.

Examples:

- creating resources;
- changing tags;
- modifying Security Groups;
- IAM activity.

VPC Flow Logs record network-flow metadata.

Examples:

- source and destination addresses;
- ports;
- protocol;
- ACCEPT or REJECT action.

Using both services provides different layers of evidence during an investigation.

## 7. An ACCEPT Record Does Not Mean an Attacker Logged In

During SSH analysis, VPC Flow Logs contained both `ACCEPT` and `REJECT` events.

The important lesson was:

> `ACCEPT` means the network path permitted the traffic. It does not prove successful SSH authentication.

To prove successful access, I would need host-level evidence such as:

```bash
sudo journalctl -u sshd
```

and entries showing successful authentication.

This distinction prevents overclaiming an incident based only on network telemetry.

## 8. Logs Insights Queries Can Fail Because of Field Naming

One CloudWatch Logs Insights query produced:

```text
Ephemeral field is already defined
```

The issue occurred because the query attempted to create a field with the same name as a field CloudWatch had already discovered automatically.

The correction was to use the existing discovered fields rather than parsing them again with duplicate names.

This taught me to inspect the available log schema before writing more complex queries.

## 9. Detection Is Stronger When the Entire Pipeline Is Tested

Creating a CloudWatch alarm was not enough. The project became much stronger when I validated the complete path:

```text
VPC Flow Logs
 -> CloudWatch Logs
 -> Metric Filter
 -> Custom Metric
 -> CloudWatch Alarm
 -> Amazon SNS
 -> Email Notification
```

Receiving the actual alert confirmed that the pipeline worked end-to-end.

## 10. Root Account Usage Should Be Minimized

The project included a transition away from routine root administration.

Security improvements included:

- Multi-Factor Authentication (MFA) on root;
- no active root access keys;
- a dedicated IAM administrator;
- MFA on the administrator;
- routine work performed with the IAM identity instead of root.

For a production workforce environment, temporary credentials and AWS IAM Identity Center would generally be preferable to long-lived administrator credentials.

## 11. Terraform Exposes Configuration Gaps Clearly

The first Terraform deployment revealed omissions that were easier to notice during testing:

- the EC2 instances originally lacked the expected SSH key configuration;
- the public web server initially lacked its Apache bootstrap configuration.

The corrections were made in Terraform instead of manually fixing the resources in the console.

That reinforced an Infrastructure-as-Code principle:

> Fix the source configuration, not only the deployed resource.

## 12. Security Changes Can Require Resource Replacement

Adding encrypted root EBS configuration caused Terraform to plan replacement of the EC2 instances.

Rather than immediately applying the change, I reviewed the plan and understood the impact first.

The workflow became:

```text
Change code
 -> terraform plan
 -> identify replacement
 -> review impact
 -> terraform apply
 -> revalidate services
```

This demonstrated controlled change management rather than treating `terraform apply` as an automatic step.

## 13. Dynamic Public IP Addresses Can Change After Replacement

After Terraform replaced the public EC2 instance, its public IPv4 address changed.

This was expected because the instance used a dynamically assigned public address rather than a persistent Elastic IP.

The lesson was that infrastructure replacement can also change dependent operational details, so post-change validation is essential.

## 14. Successful Deployment Is Not the Same as Successful Validation

A Terraform `Apply complete` message only confirms that Terraform completed the requested API operations.

After replacement, I still validated:

- the web service;
- bastion SSH access;
- private SSH access;
- NAT egress;
- storage encryption;
- metadata-service settings;
- final Terraform drift state.

The final check returned:

```text
No changes. Your infrastructure matches the configuration.
```

This became one of the strongest lessons from the project: **security engineering requires evidence after change.**

## 15. Public Portfolio Security Matters

A cloud-security portfolio should never create a new security problem.

Before publishing this repository, I intentionally excluded or sanitized:

- AWS secret access keys;
- access-key identifiers;
- private `.pem` files;
- Terraform state files;
- real `terraform.tfvars` files;
- account identifiers;
- MFA secrets and QR codes;
- subscription/unsubscribe links;
- sensitive console identifiers.

The public repository demonstrates the architecture and reasoning without exposing credentials.

## Final Takeaway

The most important outcome of the lab was not learning where AWS console buttons are located. It was learning to reason through a cloud system from multiple perspectives:

```text
Network architecture
+ Identity
+ Linux
+ Security telemetry
+ Detection logic
+ Incident investigation
+ Infrastructure as Code
+ Change management
+ Validation
```

That end-to-end reasoning is the skill I intend to continue developing in cloud security engineering and graduate computer-science study.
