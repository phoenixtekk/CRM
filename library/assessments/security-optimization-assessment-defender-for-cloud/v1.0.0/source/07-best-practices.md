# 7. Best Practices — Security Optimization Assessment: Defender for Cloud

Field-proven guidance for running this assessment well and keeping the result trustworthy over time.

## Keep it read-only and provably so
- Run with **Security Reader** + **Reader** only. If a script ever attempts a write or requests Security Admin/Contributor, treat it as a defect and stop — this assessment must prove it changed nothing.
- Record the roles and subscription context used alongside the findings report as evidence of read-only execution.

## Score against a named, current baseline
- Always record **which** best-practice baseline you scored against and its date (Global Requirements G6). The Microsoft cloud security benchmark and Secure Score controls evolve — *verify against current Microsoft guidance* each cycle.
- Where organizational policy intentionally deviates, mark it as an **accepted deviation** rather than a permanent gap.

## Treat unlicensed plans honestly
- A paid plan being off is a **coverage finding**, not automatically a defect. The finding is "enable this plan to gain the protection/posture," and enabling it **has a cost the customer must accept**. Do not present plan-on as free.
- Prioritize plan findings by the **sensitivity of the workloads** on that subscription, not by plan count.

## Make the score comparable across runs
- Keep the **scoring weights** fixed between runs (in `SOAMDC-Score.ps1`). If the owner changes a weight, record it in `SOA Scope – Defender for Cloud – Assess` and note the discontinuity.
- Re-use the saved baseline so `SOAMDC-Report.ps1` can show **drift** — a rising Secure Score across runs is the real proof of progress.

## Allow warm-up before trusting fresh numbers
- Secure Score, recommendations, and agentless-scan results **take time to populate** after any change. If a subscription was recently modified, note that the snapshot may be mid-warm-up and re-run later.

## Respect the decision boundary
- **Risk-acceptance**, **remediation priority**, the **choice of regulatory standard**, and any **incident-response** call belong to the customer's security, compliance, and SOC functions. The assessment supplies evidence and a technical score.

## Handle the output as sensitive
- The findings report is a roadmap of your cloud weaknesses. Store it in the restricted location (R6 / Global Requirements G7) and share on a need-to-know basis.

## Where to go next (adjacent catalog areas)
- **Remediation Playbook for Defender Security Optimization Assessments** — closes the findings pilot-first, `-WhatIf`-gated, then re-scores. The natural next step.
- **Microsoft Defender for Cloud: CSPM & Secure Score Remediation** — for standing up the remediation cadence and enabling Defender CSPM/agentless scanning if the assessment shows the environment is barely tuned.
- **Security Optimization Assessment — Microsoft Defender (Suite / XDR)** — to assess the whole Defender suite and unified RBAC/incident posture, not just cloud workloads.
- **Security Optimization Assessment — Defender for Cloud Apps** — the sibling assessment for the SaaS/CASB side.
