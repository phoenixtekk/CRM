# Executive Summary — AWS Security Hub & GuardDuty Enablement

**AWS**

Most AWS environments run without their two built-in security services turned on: Amazon GuardDuty, which continuously watches account activity, network flow, and DNS for threats, and AWS Security Hub, which scores your accounts against security standards and aggregates findings into one place. Left off, threats and misconfigurations stay invisible until they become an incident, and each account is its own silo with no central view. This solution enables both services **org-wide through a delegated administrator**, turns on the CIS AWS Foundations and AWS Foundational Security Best Practices standards, aggregates findings across every account and region, and builds a triage-and-response workflow — including an automated, explicitly gated response path for high-severity findings.

This is a complete, deploy-it-carefully package for standing up AWS threat detection and posture management, written for an administrator who is new to AWS Organizations, GuardDuty, and Security Hub.

## What you get

- A plain-language Solution Overview of how GuardDuty and Security Hub work, how delegated administration makes them org-wide, and how findings aggregate into a single region and queue.
- A Requirements Guide with verify / implement-if-missing for every solution-specific prerequisite (the AWS category prerequisites are published once in the separate Global Requirements).
- An Implementation Guide of precise, ordered steps — register the delegated admin, auto-enable new accounts, turn on the standards, set the aggregation Region, and wire the gated response path — always non-production first.
- Five automation artifacts: an AWS CLI discovery script, an AWS CLI validation script, an AWS CLI findings/posture report, a Terraform configuration for org-wide enablement (plan-first), and a **separately gated** Terraform configuration for the EventBridge -> Lambda/SNS automated response (disabled by default).
- Testing and Troubleshooting guides, plus a findings triage, suppression, and remediation runbook.

## What this delivers

Continuous threat detection and posture scoring across the whole organization: GuardDuty analyzing every account, Security Hub scoring them against CIS and AWS FSBP, all findings collected into one aggregation Region and one prioritized queue, high-severity findings routed to a notification/response path you control, and a documented triage runbook — instead of silent, per-account blind spots.

## The standard deployment model

`Assess -> Configure -> Pilot -> Validate -> Expand`, with a pilot gate that proves enablement, aggregation, and (in preview) the response path in a non-production account and one Region before auto-enabling the whole organization or activating any automated action.

> Security Hub standards content, control availability, GuardDuty finding types, and the **pricing** of both services change over time and vary by Region and partition (commercial vs GovCloud). *Verify current standards, controls, finding types, and pricing for your organization before you rely on them or enable at scale.*

## Outcome

Org-wide AWS threat detection and posture management with one aggregated, actioned findings queue and a controlled automated-response path — proven on a non-production pilot before organization-wide expansion.
