# 1. Solution Overview — AWS Security Hub & GuardDuty Enablement

## What this solution is

Two native AWS security services do the heavy lifting here:

- **Amazon GuardDuty** is a continuous threat-detection service. It analyzes AWS data sources — CloudTrail management and data events, VPC flow logs, and DNS query logs (plus optional protection plans for S3, EKS, Lambda, RDS, and malware) — and raises **findings** when it spots likely-malicious or unauthorized behavior. You don't deploy agents; it reads the telemetry AWS already has.
- **AWS Security Hub** is a cloud security posture management (CSPM) and findings-aggregation service. It runs **security standards** (sets of automated controls) against your resources, gives you a **security score**, and collects findings from GuardDuty and other services into one normalized format (ASFF) and one console.

This solution turns both on across your **whole organization** using **delegated administration**, so a single security account manages detection and posture for every member account, and consolidates all findings into one **aggregation Region**.

## How org-wide enablement works

1. **Delegated administrator.** From the Organizations management account you register a dedicated **Security account** as the delegated administrator for GuardDuty and for Security Hub. Day-to-day security operations then happen in that account, not the management account.
2. **Auto-enable for the organization.** In the delegated admin you turn on **auto-enable**, so GuardDuty and Security Hub (and the chosen standards) are switched on automatically for every existing and **future** member account — no per-account clicking.
3. **Standards.** In Security Hub you enable **CIS AWS Foundations Benchmark** and **AWS Foundational Security Best Practices (FSBP)**. Each standard is a bundle of controls that continuously check configuration and produce pass/fail findings that feed the security score.
4. **Finding aggregation.** GuardDuty findings flow into Security Hub. You designate one **aggregation Region** and link the other Regions, so all findings from all accounts and Regions land in a single queue.
5. **Response (gated).** An **EventBridge** rule matches high-severity Security Hub findings and routes them to **SNS** (notification) and optionally a **Lambda** (automated action). This response path is **disabled by default** and enabled only after you have validated it in preview.

## The objects this solution creates (naming convention)

Every object follows `<Purpose> – <Scope> – <Stage>` so the same names appear in the steps, the scripts, the tests, and troubleshooting:

- **Security account** — the member account registered as delegated administrator for both services.
- **Aggregation Region** — the single Region where findings are consolidated.
- **EventBridge rule:** `SecFindings-HighSeverity – Org – Response` (matches high/critical Security Hub findings).
- **SNS topic:** `SecFindings-Notify – Org – Prod` (the notification target for the rule).
- **Lambda function (optional, gated):** `SecFindings-AutoRespond – Org – Gated` (automated action; deployed disabled).
- **Suppression rules (Security Hub automation rules):** named `Suppress-<control/finding> – <scope> – Prod` as you tune noise (e.g. `Suppress-CIS-1.20 – Sandbox – Prod`).

## What you can control

- Which member accounts are covered (auto-enable vs selective) and which **GuardDuty protection plans** you turn on (each has its own cost).
- Which **standards** and which individual **controls** are enabled or disabled (with a documented reason).
- The single **aggregation Region** and which Regions link to it.
- Severity thresholds for the response rule, and whether the response is **notify-only** or **notify + automated action**.
- Suppression/automation rules that mute known-accepted findings so the queue stays actionable.

## Why this matters (the business case)

- **Detection** — GuardDuty surfaces credential misuse, reconnaissance, crypto-mining, and exfiltration patterns that are otherwise invisible.
- **Posture** — Security Hub's CIS/FSBP score turns "are we configured safely?" into a measurable number you can drive down over time.
- **Single pane** — all findings, all accounts, all Regions, one queue — instead of logging into each account to look.
- **Controlled response** — high-severity findings notify (and optionally act) automatically, but only after you have proven the path in preview.
- **Auditability** — every object is named to a convention, so the deployment is documented and repeatable.

## Limitations (be honest with buyers)

- GuardDuty and Security Hub both **bill on usage** (events/flow logs analyzed, protection plans, finding ingestion). Costs scale with account count and traffic. *Verify current pricing per Region/partition before enabling at scale.*
- Enabling the standards produces a large initial burst of findings — most are configuration gaps to triage, not active attacks. Plan triage capacity.
- This solution enables detection, posture, aggregation, and a gated response; it is **not** a full SOC, detection-engineering, or incident-response program (those build on this foundation).
- Standards content and control availability change and differ by Region/partition. *Verify current standards and controls for your organization.*

## The standard deployment model

> Assess org readiness and current security-service state, configure delegated admin + auto-enable + standards + aggregation + the gated response path, pilot in a non-production account and one Region, validate detection/aggregation/response at explicit gates, then expand org-wide and turn the response path from preview to active. Standard pattern: `Assess -> Configure -> Pilot -> Validate -> Expand`.
