# 7. Best Practices — Security Optimization Assessment: Defender for Cloud Apps

Field-proven guidance for running this assessment well and keeping the result trustworthy over time.

## Keep it read-only and provably so
- Run with **Security Reader / Global Reader** only. If a script ever requests a write or `ReadWrite` scope, treat it as a defect and stop — this assessment must be able to prove it changed nothing.
- Store the connection scopes you used alongside the findings report as evidence of read-only execution.

## Score against a named, current baseline
- Always record **which** best-practice baseline you scored against and its date (Global Requirements G6). Microsoft's guidance for Defender for Cloud Apps evolves — *verify against current Microsoft guidance* each cycle.
- Where organizational policy intentionally deviates from the baseline, note it as an **accepted deviation** rather than letting it read as a gap forever.

## Make the score comparable across runs
- Keep the **scoring weights** fixed between runs (in `SOAMCA-Score.ps1`). If the security owner changes a weight, record it in `SOA Scope – Cloud Apps – Assess` and note that scores before/after are not directly comparable.
- Re-use the saved baseline so `SOAMCA-Report.ps1` can show **drift** — trending posture is more valuable than a single snapshot.

## Prioritize by real risk, not by count
- The report ranks by **severity × exposure**. Resist "fix the easy ones first"; an unverified, over-permissioned OAuth app with tenant-wide data access outranks a dozen cosmetic alert-tuning items.
- Treat **OAuth / app-governance** findings with particular care — consent-grant attacks are a common, high-impact path and app governance is easy to leave unlicensed/unconfigured.

## Respect the decision boundary
- The assessment supplies **evidence and a technical score**. **Risk-acceptance**, **remediation priority**, and any **regulatory or incident-response** call belong to the customer's security, compliance, and SOC functions. Record accepted risks with justification and expiry.

## Handle the output as sensitive
- The findings report is a roadmap of your weaknesses. Store it in the restricted location (R6 / Global Requirements G7) and share on a need-to-know basis.

## Re-run on a cadence
- Posture drifts as apps are connected, users change, and policies age. Schedule the assessment (for example quarterly, and after any major SaaS onboarding) to keep the score current.

## Where to go next (adjacent catalog areas)
- **Remediation Playbook for Defender Security Optimization Assessments** — closes the findings pilot-first, `-WhatIf`-gated, then re-scores to prove closure. This is the natural next step.
- **Onboarding Accelerator — Microsoft Defender for Cloud Apps** — if the assessment reveals the service is barely provisioned, start here.
- **Cloud App DLP with Defender for Cloud Apps** — for designing the file/DLP policies the assessment measures.
- **Security Optimization Assessment — Microsoft Defender (Suite / XDR)** — to assess the whole Defender suite (endpoint/identity/email/cloud-apps/cloud) and unified RBAC/incident posture, not just Cloud Apps.
- **Security Optimization Assessment — Defender for Cloud** — the sibling assessment for Azure/multicloud workload posture.
