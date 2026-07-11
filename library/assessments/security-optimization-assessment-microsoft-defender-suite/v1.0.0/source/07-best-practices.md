# 7. Best Practices — Security Optimization Assessment: Microsoft Defender (Suite / XDR)

Field-proven guidance for running this suite assessment well and keeping the result trustworthy over time.

## Keep it read-only and provably so
- Run with **Security Reader / Global Reader** only. If a script ever requests a write scope or role, treat it as a defect and stop — this assessment must prove it changed nothing.
- Record the scopes/roles used alongside the findings report as evidence of read-only execution.

## Assess the glue, not just the pillars
- The value of this assessment over the single-pillar ones is the **cross-pillar coverage**, **unified RBAC**, and **incident correlation** — the glue that makes XDR more than five separate products. Give the glue domains real attention; a fully-onboarded pillar with broken correlation still leaves you blind.
- Where a pillar needs a deep review, point to its **dedicated assessment** (Cloud Apps / Cloud) rather than duplicating that depth here.

## Treat unlicensed / dark pillars honestly
- A dark or unlicensed pillar is a **coverage finding** ("license/onboard to gain this pillar"), and onboarding has a licensing cost the customer accepts. Mark genuinely not-applicable pillars (e.g. no Azure → cloud pillar) as **N/A** in the scope so they don't read as gaps forever.

## Least privilege is the point of unified RBAC
- Flag both **over-privileged** (analysts with broad Global/Security Admin) and **under-privileged** (analysts who can't see across an incident) as findings — unified RBAC exists to fix both. Broad standing privilege is a high-risk finding; prioritize it.

## Make the score comparable across runs
- Keep the **scoring weights** fixed between runs (in `SOAXDR-Score.ps1`). If the owner changes a weight, record it in `SOA Scope – Defender Suite – Assess`.
- Re-use the saved baseline so `SOAXDR-Report.ps1` can show **drift** — a rising suite Secure Score and pillars going from dark to onboarded is the real proof of progress.

## Allow warm-up and account for correlation latency
- Secure Score and incident correlation **take time to reflect changes**. If a pillar was recently onboarded, note the snapshot may be mid-warm-up and re-run later before trusting the correlation evidence.

## Respect the decision boundary
- **Risk-acceptance**, **remediation priority**, and any **regulatory / incident-response** call belong to the customer's security, compliance, and SOC functions. The assessment supplies evidence and a technical score.

## Handle the output as sensitive
- The findings report maps your suite-wide weaknesses and privileged-access exposure. Store it in the restricted location (R6 / Global Requirements G7) and share on a need-to-know basis.

## Where to go next (adjacent catalog areas)
- **Remediation Playbook for Defender Security Optimization Assessments** — closes the findings pilot-first, `-WhatIf`-gated, then re-scores. The natural next step.
- **Security Optimization Assessment — Defender for Cloud Apps** and **— Defender for Cloud** — the deep-dive assessments for those pillars.
- **Microsoft Defender XDR Deployment — Unified Onboarding** — if the assessment shows the suite is barely stitched together.
- **SOC Onboarding (Sentinel + Defender XDR)** and **Threat Hunting (KQL)** — to operationalize the correlated incidents once coverage is solid.
