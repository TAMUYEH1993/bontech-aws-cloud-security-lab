# CloudWatch Logs Insights Investigation Queries

This file documents reusable queries used during the BonTech AWS Cloud Security Lab to investigate VPC Flow Logs and rejected SSH traffic.

> Public portfolio note: example IP addresses and identifiers are intentionally generic or redacted.

## 1. Review Recent Rejected Traffic

```sql
fields @timestamp, srcAddr, dstAddr, srcPort, dstPort, protocol, action
| filter action = "REJECT"
| sort @timestamp desc
| limit 50
```

Purpose: quickly review the most recent rejected network flows and identify suspicious patterns.

## 2. Top Rejected Source IP Addresses

```sql
fields srcAddr, action
| filter action = "REJECT"
| stats count(*) as rejected_connections by srcAddr
| sort rejected_connections desc
| limit 20
```

Purpose: identify source addresses generating the largest number of rejected connections.

## 3. Top Rejected Destination Ports

```sql
fields dstPort, action
| filter action = "REJECT"
| stats count(*) as rejected_connections by dstPort
| sort rejected_connections desc
| limit 20
```

Purpose: identify which services are being probed most often.

Common examples include:

- TCP/22 — Secure Shell (SSH)
- TCP/80 — Hypertext Transfer Protocol (HTTP)
- TCP/443 — Hypertext Transfer Protocol Secure (HTTPS)
- TCP/3389 — Remote Desktop Protocol (RDP)

## 4. Investigate SSH Traffic

```sql
fields @timestamp, srcAddr, dstAddr, srcPort, dstPort, action
| filter dstPort = 22
| sort @timestamp desc
| limit 100
```

Purpose: isolate traffic targeting SSH.

## 5. Compare ACCEPT and REJECT for One Source

Replace `<SOURCE_IP>` with the source under investigation.

```sql
fields @timestamp, srcAddr, dstAddr, srcPort, dstPort, action
| filter srcAddr = "<SOURCE_IP>"
| filter dstPort = 22
| stats count(*) as connections by action
```

Purpose: compare allowed versus rejected network flows for the same source.

## 6. Timeline for a Specific Source

```sql
fields @timestamp, srcAddr, dstAddr, srcPort, dstPort, action
| filter srcAddr = "<SOURCE_IP>"
| sort @timestamp asc
| limit 200
```

Purpose: reconstruct a basic activity timeline for one source address.

## Important Analytical Lesson

A VPC Flow Log record with `action = ACCEPT` means the network layer permitted the flow. It does **not** prove that:

- SSH authentication succeeded;
- a valid username was used;
- a private key was accepted;
- a user obtained a shell;
- the EC2 instance was compromised.

Host authentication evidence must be correlated before reaching that conclusion. On Amazon Linux, examples include:

```bash
sudo journalctl -u sshd
```

or other host-level authentication logs depending on the operating system and logging configuration.

## Troubleshooting Note

During the lab, one Logs Insights query produced an **"Ephemeral field is already defined"** error. The issue occurred because a field discovered automatically by CloudWatch was also being created again with `parse`. The correction was to avoid redefining an already discovered field and use the native VPC Flow Log fields directly.

## Investigation Workflow

A practical investigation sequence is:

```text
Alert
  -> Identify source and destination
  -> Review VPC Flow Logs
  -> Determine ACCEPT vs REJECT
  -> Check Security Group / route context
  -> Correlate host authentication logs
  -> Review CloudTrail if configuration changes are suspected
  -> Decide whether activity is benign, blocked probing, or a confirmed incident
```
