# 7. Best Practices — Technical Blocker Mitigation: Defender for Cloud

Field-proven guidance for diagnosing a stalled Defender for Cloud rollout cleanly, fixing the *right* thing, and respecting the cost impact of paid plans.

## Diagnose before you enable anything paid
- Run `TBMMDC-Discovery.ps1` and `TBMMDC-Coverage.ps1` **first**. Read the signal chain top-down; the earliest broken link is the blocker. Enabling a paid plan has **cost impact** — never flip plans on a hunch.
- A "plan is On but nothing is protected" symptom is almost always a **coverage** (agent/agentless) gap, not a plan problem — confirm coverage before touching the plan.

## Change one thing, on the affected scope, change-approved, then verify
- Apply exactly **one** documented fix, to the subscription/connector in `MDC Blocker Triage – Affected Scope – Diagnose`, change-approved, then run `TBMMDC-Validate.ps1`. One change at a time keeps cause and effect clear.
- Never resume the estate-wide rollout until the affected scope passes its test gate.

## Watch for plans that silently revert
- A plan that will not stay **On** is often overridden by an **Azure Policy / deny assignment** or a management-group setting, or blocked by an unregistered **resource provider**. Check those before assuming the plan toggle is broken.

## Coverage: know agent vs agentless
- Distinguish an **agent-provisioning** gap (auto-provisioning off / workspace unreachable) from an **agentless** gap (scanning not enabled). They look the same ("no data") but have different fixes — `TBMMDC-Coverage.ps1` separates them.

## Multicloud is a permissions problem until proven otherwise
- AWS/GCP connector failures almost always trace to the **CloudFormation role** (AWS) or **service account / Terraform** (GCP). Re-run onboarding with the correct permissions rather than deleting and guessing. *Verify current multicloud requirements.*

## Let plans, coverage, connectors, and assessments warm up
- Plan enablement, provisioning, connector sync, and assessment evaluation populate over **hours**. Give a fix time before calling it a failure, then re-validate.

## Keep licensing, plan, and cost facts current
- Plan names, pricing, and capabilities **change**. Before enabling anything, *verify current plan names/pricing in your tenant* — and the enable decision, with its cost, is the customer's.

## Escalate with evidence, not a description
- If the blocker survives a correct fix, attach `MDC Support Bundle – <case> – Escalate` (discovery + coverage) to the case. A complete bundle resolves cases far faster than a written symptom.

## Where to go next
Once the rollout is unblocked, natural next steps in the catalog:
- **Defender for Cloud — CSPM & Secure Score Remediation** to move from "onboarded" to "hardened" and drive the score up.
- **Defender XDR Deployment & Unified Onboarding** to correlate cloud-workload alerts with endpoint, identity, and email signal in one portal.
- The **Sentinel** SOC/XDR integration to stream Defender for Cloud alerts into a SIEM for long-term hunting and SOAR.
