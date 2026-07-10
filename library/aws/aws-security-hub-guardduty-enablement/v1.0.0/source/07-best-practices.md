# 7. Best Practices — AWS Security Hub & GuardDuty Enablement

## Keep it clean

- **Delegate out of the management account.** Run detection and posture from the dedicated **Security account** delegated administrator, not the Organizations management account. The management account should hold as little operational workload as possible.
- **Auto-enable, always.** Turn on auto-enable so every existing and future member account gets GuardDuty and Security Hub automatically. New accounts are the ones most likely to be forgotten — and attacked.
- **One aggregation Region.** Consolidate all findings into a single aggregation Region so there is one queue to work. Pick it once (aligned to data residency) and link the rest.
- **Enable detection everywhere, even unused Regions.** Attackers spin up resources in Regions you never use. At minimum keep GuardDuty on in all Regions you can operate; centralize the findings.
- **Terraform is the source of truth.** Make enablement, standards, and the response path through `AWSSEC-guardduty-securityhub.tf` and `AWSSEC-response.tf`, plan-first and reviewed. Console clicks drift and are hard to audit.
- **Treat the response path as loaded until proven.** Keep `enable_response`/`enable_auto_action` false until you have validated notification in preview. Automated remediation is powerful and dangerous — enable it deliberately, per finding type, with logging and rollback.
- **Triage the initial burst; suppress with reasons.** Enabling standards produces many configuration findings at once. Work them down and use named suppression rules (`Suppress-<control> – <scope> – Prod`) with a recorded justification for anything you mute — never suppress blindly.
- **Drive the score down over time.** The Security Hub score is a trend, not a one-time number. Track it per account and remediate the highest-severity failing controls first.
- **Right-size protection plans.** Each GuardDuty protection plan (S3, EKS, Malware, Lambda, RDS) adds cost and coverage. Enable the ones that match your workloads; don't pay for what you don't run.
- **Watch the bill.** Both services bill on usage and it scales with account count and traffic. Review cost after enabling at scale. *Verify current pricing per Region/partition.*
- **Re-verify facts.** Standards content, control IDs, GuardDuty finding types, Region availability, and pricing all change. Before relying on a specific control or finding type, *verify current availability for your organization.*

## Defer the decisions that aren't yours

Which standards and protection plans to run, which controls may be disabled or suppressed, whether automated remediation may act on production and for which finding types, and how findings map to your incident-response process are security-governance and change-control decisions for the customer's security and operations owners. This solution provides the detection, posture, aggregation, and a gated response mechanism — not the risk-acceptance or remediation-authority policy.

## Where to go next (adjacent catalog areas)

- **AWS landing zone / Organizations baseline** — the OU structure, SCPs, and account factory that this security layer monitors across.
- **AWS IAM Identity Center + Entra SSO federation** — federate least-privilege access so the accounts you are now monitoring are also accessed safely.
- **Microsoft Sentinel telemetry pipelines** — forward AWS Security Hub findings into a central SIEM if your SOC standardizes on Sentinel.
- **Incident-response runbook** — build the response playbooks that the high-severity findings and the gated automation feed into.
