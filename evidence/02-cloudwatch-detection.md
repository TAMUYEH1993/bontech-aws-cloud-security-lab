# Evidence 02 — CloudWatch Detection and Alerting

## Objective

Convert raw rejected network traffic into an actionable cloud-security alert.

## Detection pipeline

```text
VPC Flow Logs
    -> CloudWatch Logs
        -> Metric Filter
            -> RejectedTrafficCount
                -> CloudWatch Alarm
                    -> Amazon SNS
                        -> Email notification
```

## Configuration

- Custom metric namespace: `BonTech/Security`
- Metric: `RejectedTrafficCount`
- Statistic: `Sum`
- Alarm condition: more than 5 rejected connections in a 1-minute evaluation period
- Notification path: CloudWatch Alarm -> Amazon Simple Notification Service (SNS) -> email

## Validation

The detection pipeline generated a real alarm transition after rejected traffic crossed the configured threshold. The alert notification confirmed that the chain from network telemetry to notification was working end to end.

This demonstrated that the project was not limited to collecting logs. The telemetry was converted into a measurable security signal and then into an operational notification.

## Security reasoning

A useful detection requires more than a threshold. The alert must be investigated in context. Rejected traffic can indicate scanning, misconfiguration, repeated access attempts, or benign noise. The alarm therefore acts as a triage trigger rather than automatic proof of malicious activity.

## Skills demonstrated

- Detection engineering
- CloudWatch custom metrics
- Threshold-based alerting
- Amazon SNS integration
- SOC triage workflow
- Distinguishing an alert from a confirmed incident
