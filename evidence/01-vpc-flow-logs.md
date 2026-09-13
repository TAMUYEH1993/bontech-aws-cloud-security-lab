# Evidence 01 — VPC Flow Logs Investigation

## Objective

Verify that the lab generated usable network telemetry and demonstrate how that telemetry can support a SOC-style investigation.

## What I configured

- VPC Flow Logs
- Amazon CloudWatch Logs destination
- Log group: `BonTech-VPC-Flow-Logs-Group`
- CloudWatch Logs Insights queries for rejected traffic and SSH analysis

## What I observed

The log stream contained both `ACCEPT` and `REJECT` network-flow records across the lab interfaces. I used the records to identify repeated connection attempts and to examine traffic targeting TCP port `22` (SSH).

One investigated source produced multiple rejected SSH connection attempts during the selected time window.

## Key security conclusion

A VPC Flow Log `ACCEPT` record does **not** prove that a user authenticated successfully to SSH.

`ACCEPT` means the network layer permitted the traffic according to the relevant controls. To determine whether SSH access actually succeeded, the network evidence must be correlated with host authentication logs such as `sshd` journal entries.

This distinction is important because it prevents a SOC analyst from incorrectly declaring a compromise based only on network-flow metadata.

## Example investigation query

```text
fields @timestamp, @message
| filter @message like /REJECT/
| sort @timestamp desc
| limit 50
```

For reusable queries, see [`../queries/cloudwatch-logs-insights.md`](../queries/cloudwatch-logs-insights.md).

## Skills demonstrated

- Network telemetry analysis
- Security-event triage
- Layer-3/4 versus authentication-layer reasoning
- CloudWatch Logs Insights
- Evidence-based incident analysis
